open Lwt.Infix

module Main
    (N : Mirage_net.S)
    (E : Ethernet.S)
    (I : Tcpip.Ip.S with type ipaddr = Ipaddr.V6.t) =
struct
  let start n e i =
    let handler s ~src ~dst _data =
      Logs.warn (fun m -> m "%a > %a %s" Ipaddr.V6.pp src Ipaddr.V6.pp dst s);
      Lwt.return_unit
    in
    N.listen n ~header_size:Ethernet.Packet.sizeof_ethernet
      (E.input
         ~arpv4:(fun _ ->
           Logs.err (fun m -> m "ARP4");
           Lwt.return_unit)
         ~ipv4:(fun _ ->
           Logs.err (fun m -> m "IP4");
           Lwt.return_unit)
         ~ipv6:
           (I.input ~tcp:(handler "TCP") ~udp:(handler "UDP")
              ~default:(fun ~proto ~src:_ ~dst:_ _data ->
                Logs.err (fun m -> m "%d DEFAULT" proto);
                Lwt.return_unit)
              i)
         e)
    >|= function
    | Result.Ok () -> Logs.info (fun m -> m "done!")
    | Result.Error _ -> Logs.err (fun m -> m "ipv6 ping failed!")
end
