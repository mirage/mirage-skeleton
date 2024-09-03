open Rresult
open Lwt.Infix
open Cmdliner

let port =
  let doc = Arg.info ~doc:"Port of HTTP service." [ "p"; "port" ] in
  Arg.(value & opt int 8080 doc)

let use_tls =
  let doc =
    Arg.info ~doc:"Start an HTTP server with a TLS certificate." [ "tls" ]
  in
  Arg.(value & flag doc)

let tls_port =
  let doc = Arg.info ~doc:"Port of HTTPS service." [ "tls-port" ] in
  Arg.(value & opt int 4343 doc)

let alpn =
  let doc = Arg.info ~doc:"Protocols handled by the HTTP server." [ "alpn" ] in
  Arg.(value & opt (some string) None doc)

type t = { use_tls : bool; tls_port : int; alpn : string option }

let setup =
  Term.(
    const (fun use_tls tls_port alpn -> { use_tls; tls_port; alpn })
    $ use_tls
    $ tls_port
    $ alpn)

let ( <.> ) f g x = f (g x)
let always x _ = x

module Make
    (Random : Mirage_crypto_rng_mirage.S)
    (Certificate : Mirage_kv.RO)
    (Key : Mirage_kv.RO)
    (Tcp : Tcpip.Tcp.S with type ipaddr = Ipaddr.t)
    (Connect : Connect.S)
    (HTTP_server : Paf_mirage.S) =
struct
  let tls key_ro certificate_ro =
    let open Lwt_result.Infix in
    Lwt.Infix.(
      Key.list key_ro Mirage_kv.Key.empty
      >|= R.reword_error (R.msgf "%a" Key.pp_error))
    >>= fun keys ->
    let keys, _ = List.partition (fun (_, t) -> t = `Value) keys in
    Lwt.Infix.(
      Certificate.list certificate_ro Mirage_kv.Key.empty
      >|= R.reword_error (R.msgf "%a" Certificate.pp_error))
    >>= fun certificates ->
    let certificates, _ =
      List.partition (fun (_, t) -> t = `Value) certificates
    in
    let fold acc (name, _) =
      match Mirage_kv.Key.basename name with
      | ".gitkeep" -> Lwt.return acc
      | _ ->
          let open Lwt_result.Infix in
          Lwt.Infix.(
            Certificate.get certificate_ro name
            >|= R.reword_error (R.msgf "%a" Certificate.pp_error))
          >>= (Lwt.return <.> X509.Certificate.decode_pem_multiple)
          >>= fun certificates ->
          Lwt.return acc >>= fun acc ->
          Lwt.return_ok ((name, certificates) :: acc)
    in
    Lwt_list.fold_left_s fold (Ok []) certificates >>= fun certificates ->
    let fold acc (name, _) =
      match Mirage_kv.Key.basename name with
      | ".gitkeep" -> Lwt.return acc
      | _ ->
          let open Lwt_result.Infix in
          Lwt.Infix.(
            Key.get key_ro name >|= R.reword_error (R.msgf "%a" Key.pp_error))
          >>= (Lwt.return <.> X509.Private_key.decode_pem)
          >>= fun key ->
          Lwt.return acc >>= fun acc -> Lwt.return_ok ((name, key) :: acc)
    in
    Lwt_list.fold_left_s fold (Ok []) keys >>= fun keys ->
    let tbl = Hashtbl.create 0x10 in
    List.iter
      (fun (name, certificates) ->
        match List.assoc_opt name keys with
        | Some key -> Hashtbl.add tbl name (certificates, key)
        | None -> ())
      certificates;
    match Hashtbl.fold (fun _ certchain acc -> certchain :: acc) tbl [] with
    | [] -> Lwt.return_ok `None
    | [ certchain ] -> Lwt.return_ok (`Single certchain)
    | certchains -> Lwt.return_ok (`Multiple certchains)

  let http_1_1_request_handler ~ctx ~authenticator flow _edn =
    let module R = (val Mimic.repr HTTP_server.tcp_protocol) in
    fun reqd ->
      match (Httpaf.Reqd.request reqd).Httpaf.Request.meth with
      | `CONNECT ->
          HTTP_server.TCP.no_close flow;
          let to_close = function
            | R.T flow -> HTTP_server.TCP.to_close flow
            | _ -> ()
          in
          Server.http_1_1_request_handler ~ctx ~authenticator ~to_close
            (R.T flow) reqd
      | _ ->
          Server.http_1_1_request_handler ~ctx ~authenticator
            ~to_close:(always ()) (R.T flow) reqd

  let alpn_handler ~ctx ~authenticator =
    let module R = (val Mimic.repr HTTP_server.tls_protocol) in
    let to_close = function
      | R.T flow -> HTTP_server.TLS.to_close flow
      | _ -> ()
    in
    {
      Alpn.error = Server.alpn_error_handler;
      Alpn.request =
        (fun flow edn reqd protocol ->
          Server.alpn_request_handler ~ctx ~authenticator ~to_close (R.T flow)
            edn reqd protocol);
    }

  let run_with_tls ~ctx ~authenticator ~tls http_server tls_port tcpv4v6 =
    let alpn_service =
      HTTP_server.alpn_service ~tls (alpn_handler ~ctx ~authenticator)
    in
    let http_1_1_service =
      HTTP_server.http_service ~error_handler:Server.http_1_1_error_handler
        (http_1_1_request_handler ~ctx ~authenticator)
    in
    HTTP_server.init ~port:tls_port tcpv4v6 >|= Paf.serve alpn_service
    >>= fun (`Initialized th0) ->
    Paf.serve http_1_1_service http_server |> fun (`Initialized th1) ->
    Lwt.both th0 th1 >>= fun ((), ()) -> Lwt.return_unit

  let run ~ctx ~authenticator http_server =
    let http_1_1_service =
      HTTP_server.http_service ~error_handler:Server.http_1_1_error_handler
        (http_1_1_request_handler ~ctx ~authenticator)
    in
    Paf.serve http_1_1_service http_server |> fun (`Initialized th) -> th

  let start _random certificate_ro key_ro tcpv4v6 ctx http_server
      { use_tls; alpn; tls_port } =
    let open Lwt.Infix in
    let authenticator = Connect.authenticator in
    tls key_ro certificate_ro >>= fun tls ->
    if use_tls then
      let tls =
        let certificates = match tls with
          | Ok certificates -> certificates
          | Error `Msg m ->
            Fmt.failwith
              "A TLS server requires, at least, one certificate and one \
               private key. Received error %s." m
        in
        let alpn_protocols = match alpn with
          | None -> [ "h2"; "http/1.1" ]
          | Some (("http/1.1" | "h2") as proto) -> [ proto ]
          | Some proto -> Fmt.failwith "Invalid ALPN protocol %S" proto
        in
        match Tls.Config.server ~certificates ~alpn_protocols () with
        | Error `Msg m ->
          Fmt.failwith "TLS configuration error: %s." m
        | Ok tls -> tls
      in
      run_with_tls ~ctx ~authenticator ~tls http_server tls_port tcpv4v6
    else
      run ~ctx ~authenticator http_server
end
