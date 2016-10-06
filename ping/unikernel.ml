open Lwt.Infix
open V1_LWT

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let ipaddr   = "10.0.0.2"
let netmask  = "255.255.255.0"
let gateways = ["10.0.0.1"]

module Main (C:CONSOLE) (N:NETWORK) (Clock: V1.MCLOCK) (Time: V1_LWT.TIME) = struct

  module E = Ethif.Make(N)
  module A = Arpv4.Make(E)(Clock)(Time)
  module I = Ipv4.Make(E)(A)

  let start c n clock _time =
    C.log c (green "starting...");
    E.connect n >>= fun e ->
    A.connect e clock >>= fun a ->
    I.connect e a >>= fun i ->

    I.set_ip i (Ipaddr.V4.of_string_exn ipaddr) >>= fun () ->
    I.set_ip_netmask i (Ipaddr.V4.of_string_exn netmask) >>= fun () ->
    I.set_ip_gateways i (List.map Ipaddr.V4.of_string_exn gateways)
    >>= fun () ->

    let handler s = fun ~src ~dst _data ->
      C.log_s c (yellow "%s > %s %s"
                   (Ipaddr.V4.to_string src) (Ipaddr.V4.to_string dst) s)
    in
    N.listen n
      (E.input
         ~arpv4:(A.input a)
         ~ipv4:(I.input
                  ~tcp:(handler "TCP")
                  ~udp:(handler "UDP")
                  ~default:(fun ~proto ~src:_ ~dst:_ _data ->
                      C.log_s c (red "%d DEFAULT" proto))
                  i
               )
         ~ipv6:(fun _buf -> Lwt.return (C.log c (red "IP6")))
         e)
    >>= fun _ ->
    C.log c (green "done!");
    Lwt.return ()

end
