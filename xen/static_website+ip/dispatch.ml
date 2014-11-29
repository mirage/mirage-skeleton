open Lwt
open Printf
open V1_LWT

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (FS:KV_RO) (N:NETWORK) = struct

  module E = Ethif.Make(N)
  module I = Ipv4.Make(E)
  module U = Udp.Make(I)
  module T = Tcp.Flow.Make(I)(OS.Time)(Clock)(Random)
  module CH = Channel.Make(T)
  module H  = HTTP.Make(CH)

  let or_error c name fn t =
    fn t
    >>= function
    | `Error e -> fail (Failure ("Error starting " ^ name))
    | `Ok t -> return t

  let start c fs net =

    or_error c "Ethif" E.connect net >>= fun e ->
    or_error c "Ipv4" I.connect e >>= fun i ->
    let cmd_line = OS.Start_info.((get ()).cmd_line) in
    C.log_s c (sprintf "kernel command line: %s" cmd_line) >>= fun () ->
    (* Split the command line into k/v pairs *)
    let fields = Re_str.(split (regexp_string " ") cmd_line) in
    let bits =
      List.map (fun x ->
          match Re_str.(split (regexp_string "=") x) with
          | [a;b] -> (a,b)
          | _ -> raise (Failure "malformed cmdline")) fields
    in
    let get x = List.assoc x bits in
    let ip = Ipaddr.V4.of_string_exn (get "ip") in
    let netmask = Ipaddr.V4.of_string_exn (get "netmask") in
    let gateway = Ipaddr.V4.of_string_exn (get "gateway") in
    C.log_s c (sprintf "ip=%s netmask=%s gateway=%s"
                 (Ipaddr.V4.to_string ip)
                 (Ipaddr.V4.to_string netmask)
                 (Ipaddr.V4.to_string gateway)) >>= fun () ->
    I.set_ip i ip >>= fun () ->
    I.set_ip_netmask i netmask >>= fun () ->
    I.set_ip_gateways i [gateway] >>= fun () ->
    or_error c "UDPv4" U.connect i >>= fun udp ->
    or_error c "TCPv4" T.connect i >>= fun tcp ->

    let read_fs name =
      FS.size fs name
      >>= function
      | `Error (FS.Unknown_key _) -> fail (Failure ("read " ^ name))
      | `Ok size ->
        FS.read fs name 0 (Int64.to_int size)
        >>= function
        | `Error (FS.Unknown_key _) -> fail (Failure ("read " ^ name))
        | `Ok bufs -> return (Cstruct.copyv bufs)
    in

    (* Split a URI into a list of path segments *)
    let split_path uri =
      let path = Uri.path uri in
      let rec aux = function
        | [] | [""] -> []
        | hd::tl -> hd :: aux tl
      in
      List.filter (fun e -> e <> "")
        (aux (Re_str.(split_delim (regexp_string "/") path)))
    in

    (* dispatch non-file URLs *)
    let rec dispatcher = function
      | [] | [""] -> dispatcher ["index.html"]
      | segments ->
        let path = String.concat "/" segments in
        try_lwt
          read_fs path
          >>= fun body ->
          H.Server.respond_string ~status:`OK ~body ()
        with exn ->
          H.Server.respond_not_found ()
    in

    (* HTTP callback *)
    let callback conn_id request body =
      let uri = H.Server.Request.uri request in
      dispatcher (split_path uri)
    in

    let conn_closed conn_id () =
      let cid = Cohttp.Connection.to_string conn_id in
      C.log c (Printf.sprintf "conn %s closed" cid)
    in

    let http_callback conn_id req body =
      let path = Uri.path (H.Server.Request.uri req) in
      C.log_s c (sprintf "Got request for %s\n" path)
      >>= fun () ->
      H.Server.respond_string ~status:`OK ~body:"hello mirage world!\n" ()
    in

    let spec = {
      H.Server.callback = http_callback;
      conn_closed = fun _ () -> ();
    } in

    N.listen net (
      E.input
        ~arpv4:(I.input_arpv4 i)
        ~ipv4:(
          I.input
            ~tcp:(
              T.input tcp ~listeners:
                (function
                  | 80 -> Some (fun flow -> H.Server.listen spec flow)
                  | _ -> None
                ))
            ~udp:(
              U.input ~listeners:
                (fun ~dst_port -> C.log c (blue "udp packet on port %d" dst_port); None)udp
            )
            ~default:(fun ~proto ~src ~dst _ -> return ())
            i
        )
        ~ipv6:(fun b -> C.log_s c (yellow "ipv6")) e
    )
end
