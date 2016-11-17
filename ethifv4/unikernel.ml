open V1_LWT
open Lwt.Infix

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C: CONSOLE) (N: NETWORK) (Clock : V1.MCLOCK) (Time: TIME) (R : RANDOM) = struct

  module E = Ethif.Make(N)
  module A = Arpv4.Make(E)(Clock)(Time)
  module I = Static_ipv4.Make(E)(A)
  module U = Udp.Make(I)
  module T = Tcp.Flow.Make(I)(Time)(Clock)(R)

  let ip = Ipaddr.V4.of_string_exn "10.0.0.2"
  let network = Ipaddr.V4.Prefix.make 24 ip
  let gateway = Some (Ipaddr.V4.of_string_exn "10.0.0.1")

  let start c net clock _time _r =
    E.connect net >>= fun e ->
    A.connect e clock >>= fun a ->
    I.connect ~ip ~network ~gateway e a >>= fun i ->
    U.connect i >>= fun udp ->
    T.connect i clock >>= fun tcp ->

    let tcp_listeners = function
      | 80 ->
        Some (fun flow ->
            let dst, dst_port = T.dst flow in
            C.log c (green "new tcp from %s %d" (Ipaddr.V4.to_string dst) dst_port) >>= fun () ->
            T.read flow >>= function
            | Ok (`Data b) ->
              C.log c (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b)) >>= fun () ->
              T.close flow
            | Ok `Eof -> C.log c (green "read: eof")
            | Error (`Msg s) -> C.log c (red "read error: " ^ s))
      | _ -> None
    and udp_listeners ~dst_port =
      Some (fun ~src:_ ~dst:_ ~src_port:_ _ -> C.log c (blue "udp packet on port %d" dst_port))
    in

    N.listen net (
      E.input e
        ~arpv4:(A.input a)
        ~ipv4:(I.input i
                 ~tcp:(T.input tcp ~listeners:tcp_listeners)
                 ~udp:(U.input udp ~listeners:udp_listeners)
                 ~default:(fun ~proto:_ ~src:_ ~dst:_ _ -> Lwt.return_unit))
        ~ipv6:(fun _b -> C.log c (yellow "ipv6")))
end
