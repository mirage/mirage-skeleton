open Lwt.Infix

let client_src = Logs.Src.create "client" ~doc:"DNS client"
module Client_log = (val Logs.src_log client_src : Logs.LOG)

let server_src = Logs.Src.create "server" ~doc:"DNS server"
module Server_log = (val Logs.src_log server_src : Logs.LOG)

(* Settings for client test *)
let server = "8.8.8.8"
let port = 53
let client_src_port = 7000
let test_hostname = "dark.recoil.org"

(* Server settings *)
let listening_port = 53

module Main (Clock:V1.CLOCK) (K:V1_LWT.KV_RO) (S:V1_LWT.STACKV4) = struct
  module Logs_reporter = Mirage_logs.Make(Clock)

  module U = S.UDPV4

  let load_zone k =
    K.size k "test.zone"
    >>= function
    | `Error _ -> Lwt.fail (Failure "test.zone not found")
    | `Ok sz ->
      Server_log.info (fun f -> f "Loading %Ld bytes of zone data" sz);
      K.read k "test.zone" 0 (Int64.to_int sz)
      >>= function
      | `Error _ -> Lwt.fail (Failure "test.zone error reading")
      | `Ok pages -> Lwt.return (Cstruct.concat pages |> Cstruct.to_string)

  let connect_to_resolver stack server port : Dns_resolver.commfn =
    let udp = S.udpv4 stack in
    let dst = Ipaddr.V4.of_string_exn server in
    let txfn buf =
      let buf = Cstruct.of_bigarray buf in
      (* Cstruct.hexdump buf; *)
      U.write ~src_port:client_src_port ~dst ~dst_port:port udp buf in
    let st, push_st = Lwt_stream.create () in
    S.listen_udpv4 stack ~port:client_src_port (
      fun ~src:_ ~dst:_ ~src_port:_ buf ->
        Client_log.info (fun f -> f "Got resolver response, length %d" (Cstruct.len buf));
        let ba = Cstruct.to_bigarray buf in
        push_st (Some ba);
        Lwt.return ()
    );
    let rec rxfn f =
      Lwt_stream.get st
      >>= function
      | None     -> Lwt.fail (Failure "resolver flow closed")
      | Some buf -> begin
          match f buf with
          | None   -> rxfn f
          | Some r -> Lwt.return r
        end
    in
    let timerfn () = OS.Time.sleep_ns (Duration.of_sec 5) in
    let cleanfn () = Lwt.return () in
    { Dns_resolver.txfn; rxfn; timerfn; cleanfn }

  let make_client_request stack =
    OS.Time.sleep_ns (Duration.of_sec 3) >>= fun () ->
    Client_log.info (fun f -> f "Starting client resolver");
    let commfn = connect_to_resolver stack server port in
    let alloc () = (Io_page.get 1 :> Dns.Buf.t) in
    Dns_resolver.gethostbyname ~alloc commfn test_hostname
    >>= fun ips ->
    Client_log.info (fun f -> f "Got IPS: %a" Format.(pp_print_list Ipaddr.pp_hum) ips);
    Lwt.return ()

  let serve s zonebuf =
    let open Dns_server in
    let process = process_of_zonebuf zonebuf in
    let processor = (processor_of_process process :> (module PROCESSOR)) in
    let udp = S.udpv4 s in
    S.listen_udpv4 s ~port:listening_port (
      fun ~src ~dst ~src_port buf ->
        Server_log.info (fun f -> f "Got DNS query via UDP");
        let ba = Cstruct.to_bigarray buf in
        let src' = (Ipaddr.V4 dst), listening_port in
        let dst' = (Ipaddr.V4 src), src_port in
        let obuf = (Io_page.get 1 :> Dns.Buf.t) in
        process_query ba (Dns.Buf.length ba) obuf src' dst' processor >>= function
        | None ->
          Server_log.info (fun f -> f "No response");
          Lwt.return ()
        | Some rba ->
          let rbuf = Cstruct.of_bigarray rba in
          Server_log.info (fun f -> f "Sending reply");
          U.write ~src_port:listening_port ~dst:src ~dst_port:src_port udp rbuf
    );
    Server_log.info (fun f -> f "DNS server listening on UDP port %d" listening_port);
    S.listen s

  let start () kv_store stack =
    Logs.(set_level (Some Info));
    Logs_reporter.(create () |> run) @@ fun () ->
    load_zone kv_store >>= fun zonebuf ->
    Lwt.join [
      serve stack zonebuf;
      make_client_request stack
    ]
end
