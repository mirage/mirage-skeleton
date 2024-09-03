module type S = sig
  val connect : Mimic.ctx -> Mimic.ctx Lwt.t
  val authenticator : (X509.Authenticator.t, [> `Msg of string ]) result
end

open Lwt.Infix

let connect_scheme = Mimic.make ~name:"connect-scheme"
let connect_port = Mimic.make ~name:"connect-port"
let connect_hostname = Mimic.make ~name:"connect-hostname"
let connect_tls_config = Mimic.make ~name:"connect-tls-config"

module Make
    (Pclock : Mirage_clock.PCLOCK)
    (TCP : Tcpip.Tcp.S)
    (Happy_eyeballs : Mimic_happy_eyeballs.S with type flow = TCP.flow) : S =
struct
  module TCP = struct
    include TCP

    type endpoint = Happy_eyeballs.t * string * int

    type nonrec write_error =
      [ `Write of write_error | `Connect of string | `Closed ]

    let pp_write_error ppf = function
      | `Connect err -> Fmt.string ppf err
      | `Write err -> pp_write_error ppf err
      | `Closed as err -> pp_write_error ppf err

    let write flow cs =
      let open Lwt.Infix in
      write flow cs >>= function
      | Ok _ as v -> Lwt.return v
      | Error err -> Lwt.return_error (`Write err)

    let writev flow css =
      writev flow css >>= function
      | Ok _ as v -> Lwt.return v
      | Error err -> Lwt.return_error (`Write err)

    let connect (happy_eyeballs, hostname, port) =
      Happy_eyeballs.resolve happy_eyeballs hostname [ port ] >>= function
      | Error (`Msg err) -> Lwt.return_error (`Connect err)
      | Ok ((_ipaddr, _port), flow) -> Lwt.return_ok flow
  end

  let tcp_edn, _tcp_protocol = Mimic.register ~name:"tcp" (module TCP)

  module TLS = struct
    type endpoint = Happy_eyeballs.t * Tls.Config.client * string * int

    include Tls_mirage.Make (TCP)

    let connect (happy_eyeballs, cfg, hostname, port) =
      let peer_name =
        Result.(
          to_option (bind (Domain_name.of_string hostname) Domain_name.host))
      in
      Happy_eyeballs.resolve happy_eyeballs hostname [ port ] >>= function
      | Ok ((_ipaddr, _port), flow) -> client_of_flow cfg ?host:peer_name flow
      | Error (`Msg err) -> Lwt.return_error (`Write (`Connect err))
  end

  let tls_edn, _tls_protocol = Mimic.register ~name:"tls" (module TLS)

  let connect ctx =
    let k0 happy_eyeballs connect_scheme connect_hostname connect_port =
      match connect_scheme with
      | "http" ->
          Lwt.return_some (happy_eyeballs, connect_hostname, connect_port)
      | _ -> Lwt.return_none
    in
    let k1 happy_eyeballs connect_scheme connect_hostname connect_port
        tls_config =
      match connect_scheme with
      | "https" ->
          Lwt.return_some
            (happy_eyeballs, tls_config, connect_hostname, connect_port)
      | _ -> Lwt.return_none
    in
    let ctx =
      Mimic.fold tcp_edn
        Mimic.Fun.
          [
            req Happy_eyeballs.happy_eyeballs;
            req connect_scheme;
            req connect_hostname;
            dft connect_port 80;
          ]
        ~k:k0 ctx
    in
    let ctx =
      Mimic.fold tls_edn
        Mimic.Fun.
          [
            req Happy_eyeballs.happy_eyeballs;
            req connect_scheme;
            req connect_hostname;
            dft connect_port 443;
            req connect_tls_config;
          ]
        ~k:k1 ctx
    in
    Lwt.return ctx

  let authenticator =
    let module V = Ca_certs_nss.Make (Pclock) in
    V.authenticator ()
end

let decode_uri ~ctx uri =
  let ( >>= ) = Result.bind in
  match String.split_on_char '/' uri with
  | proto :: "" :: user_pass_host_port :: _path ->
      (if String.equal proto "http:" then
         Ok ("http", Mimic.add connect_scheme "http" ctx)
       else if String.equal proto "https:" then
         Ok ("https", Mimic.add connect_scheme "https" ctx)
       else Error (`Msg "Couldn't decode user and password"))
      >>= fun (_scheme, ctx) ->
      (match String.split_on_char '@' user_pass_host_port with
      | [ host_port ] -> Ok (None, host_port)
      | [ _user_pass; host_port ] -> Ok (None, host_port)
      | _ -> Error (`Msg "Couldn't decode URI"))
      >>= fun (_user_pass, host_port) ->
      (match String.split_on_char ':' host_port with
      | [] -> Error (`Msg "Empty host & port")
      | [ hostname ] -> Ok (hostname, Mimic.add connect_hostname hostname ctx)
      | hd :: tl -> (
          let port, hostname =
            match List.rev (hd :: tl) with
            | hd :: tl -> (hd, String.concat ":" (List.rev tl))
            | _ -> assert false
          in
          try
            Ok
              ( hostname,
                Mimic.add connect_hostname hostname
                  (Mimic.add connect_port (int_of_string port) ctx) )
          with Failure _ -> Error (`Msg "Couldn't decode port")))
      >>= fun (hostname, ctx) -> Ok (ctx, hostname)
  | _ -> Error (`Msg "Couldn't decode URI on top")

let tls_config ?tls_config authenticator =
  lazy
    (match tls_config with
    | Some cfg -> Ok (`Custom cfg)
    | None ->
        let alpn_protocols = [ "h2"; "http/1.1" ] in
        let ( let* ) = Result.bind in
        let* authenticator = authenticator in
        let* cfg = Tls.Config.client ~alpn_protocols ~authenticator () in
        Ok (`Default cfg))

let create_connection ?tls_config:cfg ~ctx ~authenticator uri =
  let tls_config = tls_config ?tls_config:cfg authenticator in
  let open Lwt_result.Infix in
  Lwt.return (decode_uri ~ctx uri) >>= fun (ctx, host) ->
  let ctx =
    match Lazy.force tls_config with
    | Ok (`Custom cfg) -> Mimic.add connect_tls_config cfg ctx
    | Ok (`Default cfg) -> (
        match Result.bind (Domain_name.of_string host) Domain_name.host with
        | Ok peer -> Mimic.add connect_tls_config (Tls.Config.peer cfg peer) ctx
        | Error _ -> Mimic.add connect_tls_config cfg ctx)
    | Error _ -> ctx
  in
  Mimic.resolve ctx
