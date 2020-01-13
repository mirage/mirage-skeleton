open Lwt.Infix

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:Mirage_console.S) (N: Mirage_net.S) (E: Mirage_protocols.ETHERNET) (I:Mirage_protocols.IPV6) = struct

  let start c n e i =
    let handler s = fun ~src ~dst _data ->
      C.log c (yellow "%s > %s %s" (Ipaddr.V6.to_string src) (Ipaddr.V6.to_string dst) s)
    in
    N.listen n ~header_size:Ethernet_wire.sizeof_ethernet
      (E.input
         ~arpv4:(fun _ -> C.log c (red "ARP4"))
         ~ipv4:(fun _ -> C.log c (red "IP4"))
         ~ipv6:(I.input
                  ~tcp:(handler "TCP")
                  ~udp:(handler "UDP")
                  ~default:(fun ~proto ~src:_ ~dst:_ _data ->
                      C.log c (red "%d DEFAULT" proto))
                  i
               )
         e)
    >>= function
    | Result.Ok () -> C.log c (green "done!")
    | Result.Error _ -> C.log c (red "ipv6 ping failed!")

end
