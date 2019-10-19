open Lwt.Infix

let client_src = Logs.Src.create "client" ~doc:"DNS client"
module Client_log = (val Logs.src_log client_src : Logs.LOG)

let server_src = Logs.Src.create "server" ~doc:"DNS server"
module Server_log = (val Logs.src_log server_src : Logs.LOG)

(* Settings for client test *)
let server = "8.8.8.8"
let port = 53
let test_hostname = "dark.recoil.org"

(* Server settings *)
let listening_port = 53

module Main (Time : Mirage_time_lwt.S) (K:Mirage_types_lwt.KV_RO) (S:Mirage_types_lwt.STACKV4) = struct

  module U = S.UDPV4
  module Resolver = Dns_resolver_mirage.Make(Time)(S)

  let load_zone k =
    K.get k (Mirage_kv.Key.v "test.zone") >>= function
    | Error _ -> Lwt.fail (Failure "test.zone not found")
    | Ok data ->
      Server_log.info (fun f -> f "Loaded %d bytes of zone data" (String.length data));
      Lwt.return data

  let make_client_request stack =
    Time.sleep_ns (Duration.of_sec 3) >>= fun () ->
    Client_log.info (fun f -> f "Starting client resolver");
    let resolver = Resolver.create stack in
    Lwt.catch
      (fun () ->
       Resolver.gethostbyname resolver ~server:(Ipaddr.V4.of_string_exn server)
                              ~dns_port:port test_hostname
       >>= fun ips ->
       Client_log.info (fun f -> f "Got IPS: %a" Format.(pp_print_list Ipaddr.pp) ips);
       Lwt.return ())
      (* Error handling *)
      (function
        | Dns.Protocol.Dns_resolve_error errors ->
           let exn_formatter ppf exn = Format.fprintf ppf "%s" (Printexc.to_string exn) in
           Client_log.warn
             (fun f -> f "DNS resolution for %s failed: %a" test_hostname
                         (Format.pp_print_list exn_formatter) errors);
           Lwt.return ()
        | exn -> Lwt.fail exn)

  let serve s zonebuf =
    let open Dns_server in
    let process = process_of_zonebuf zonebuf in
    let processor = (processor_of_process process :> (module PROCESSOR)) in
    let udp = S.udpv4 s in
    S.listen_udpv4 s ~port:listening_port (
      fun ~src ~dst ~src_port buf ->
        Server_log.info (fun f -> f "Got DNS query via UDP");
        let src' = (Ipaddr.V4 dst), listening_port in
        let dst' = (Ipaddr.V4 src), src_port in
        process_query buf (Cstruct.len buf) src' dst' processor >>= function
        | None ->
          Server_log.info (fun f -> f "No response");
          Lwt.return ()
        | Some rbuf ->
          Server_log.info (fun f -> f "Sending reply");
          U.write ~src_port:listening_port ~dst:src ~dst_port:src_port udp rbuf >>= function
          | Error e -> Server_log.warn (fun f -> f "Failure sending reply: %a" U.pp_error e);
            Lwt.return_unit
          | Ok () -> Lwt.return ()
    );
    Server_log.info (fun f -> f "DNS server listening on UDP port %d" listening_port);
    S.listen s

  let start _time kv_store stack =
    Logs.(set_level (Some Info));
    load_zone kv_store >>= fun zonebuf ->
    Lwt.join [
      serve stack zonebuf;
      make_client_request stack
    ]
end
