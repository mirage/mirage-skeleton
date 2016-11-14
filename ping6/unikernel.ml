open Lwt.Infix
open V1_LWT

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let ipaddr   = "fc00::2"
let gateways = ["fc00::1"]

module Main (C:CONSOLE) (N:NETWORK) (Clock : V1.MCLOCK) (Time : TIME) = struct

  module E = Ethif.Make(N)
  module I = Ipv6.Make(E)(Time)(Clock)

  let start c n clock _time =
    let gateways = (List.map Ipaddr.V6.of_string_exn gateways) in
    C.log c (green "starting...") >>= fun () ->
    E.connect n >>= fun e ->
    I.connect ~ip:(Ipaddr.V6.of_string_exn ipaddr)
              ~gateways
              e clock >>= fun i ->

    let handler s = fun ~src ~dst data ->
      C.log c (yellow "%s > %s %s" (Ipaddr.V6.to_string src) (Ipaddr.V6.to_string dst) s)
    in
    N.listen n
      (E.input
         ~arpv4:(fun _ -> C.log c (red "ARP4"))
         ~ipv4:(fun _ -> C.log c (red "IP4"))
         ~ipv6:(I.input
                  ~tcp:(handler "TCP")
                  ~udp:(handler "UDP")
                  ~default:(fun ~proto ~src ~dst data ->
                      C.log c (red "%d DEFAULT" proto))
                  i
               )
         e)
    >>= function
    | Result.Ok () -> C.log c (green "done!")
    | Result.Error _ -> C.log c (red "ipv6 ping failed!")

end
