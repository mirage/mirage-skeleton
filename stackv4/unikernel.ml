open Lwt.Infix
open V1_LWT

let red fmt    = Fmt.strf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Fmt.strf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Fmt.strf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Fmt.strf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (S:STACKV4) = struct

  module T  = S.TCPV4

  let start console s =

    let ips = List.map Ipaddr.V4.to_string (S.IPV4.get_ip (S.ipv4 s)) in
    C.log console (Fmt.strf "IP address: %s" (String.concat ", " ips))

    >>= fun () ->
    let local_port = 53 in
    S.listen_udpv4 s ~port:local_port (
      fun ~src ~dst ~src_port buf ->
        C.log console
          (red "UDP %s:%d > %s:%d: \"%s\""
             (Ipaddr.V4.to_string src) src_port
             (Ipaddr.V4.to_string dst) local_port
             (Cstruct.to_string buf))
    );

    let local_port = 8080 in
    S.listen_tcpv4 s ~port:local_port (
      fun flow ->
        let remote, remote_port = T.dst flow in
        C.log console
          (green "TCP %s:%d > _:%d"
             (Ipaddr.V4.to_string remote) remote_port local_port) >>= fun () ->
        T.read flow >>= function
        | Ok (`Data b) ->
          C.log console
            (yellow "read: %d \"%s\"" (Cstruct.len b) (Cstruct.to_string b)) >>= fun () ->
          T.close flow
        | Ok `Eof -> C.log console (green "read: eof")
        | Error e -> C.log console (red "read error: %a" T.pp_error e)
    );

    S.listen s
end
