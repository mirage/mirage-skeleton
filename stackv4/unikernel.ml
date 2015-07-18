open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (S:STACKV4) = struct

  module T  = S.TCPV4

  let start console s =

    let ips = List.map Ipaddr.V4.to_string (S.IPV4.get_ip (S.ipv4 s)) in
    C.log_s console (sprintf "IP address: %s\n" (String.concat ", " ips))

    >>= fun () ->
    let local_port = 53 in
    S.listen_udpv4 s local_port (
      fun ~src ~dst ~src_port buf ->
        C.log_s console
          (red "UDP %s:%d > %s:%d: \"%s\""
             (Ipaddr.V4.to_string src) src_port
             (Ipaddr.V4.to_string dst) local_port
             (Cstruct.to_string buf))
    );

    let local_port = 8080 in
    S.listen_tcpv4 s local_port (
      fun flow ->
        let remote, remote_port = T.get_dest flow in
        C.log_s console
          (green "TCP %s:%d > _:%d"
             (Ipaddr.V4.to_string remote) remote_port local_port)

        >>= fun () ->
        T.read flow

        >>= function
        | `Ok b ->
          C.log_s console
            (yellow "read: %d \"%s\"" (Cstruct.len b) (Cstruct.to_string b))

          >>= fun () ->
          T.close flow

        | `Eof -> C.log_s console (red "read: eof")
        | `Error e -> C.log_s console (red "read: error")
    );

    S.listen s
end
