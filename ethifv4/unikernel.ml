open V1_LWT
open Lwt.Infix

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C: CONSOLE) (N: NETWORK) (Clock : V1.CLOCK) = struct

  module E = Ethif.Make(N)
  module A = Arpv4.Make(E)(Clock)(OS.Time)
  module I = Ipv4.Make(E)(A)
  module U = Udp.Make(I)
  module T = Tcp.Flow.Make(I)(OS.Time)(Clock)(Random)
  module D = Dhcp_clientv4.Make(OS.Time)(Random)(U)

  let or_error _c name fn t =
    fn t
    >>= function
    | `Error _e -> Lwt.fail (Failure ("Error starting " ^ name))
    | `Ok t -> Lwt.return t

  let start c net _ =
    or_error c "Ethif" E.connect net
    >>= fun e ->
    or_error c "Arpv4" A.connect e
    >>= fun a ->
    or_error c "Ipv4" (I.connect e) a
    >>= fun i ->

    I.set_ip i (Ipaddr.V4.of_string_exn "10.0.0.2")
    >>= fun () ->
    I.set_ip_netmask i (Ipaddr.V4.of_string_exn "255.255.255.0")
    >>= fun () ->
    I.set_ip_gateways i [Ipaddr.V4.of_string_exn "10.0.0.1"]
    >>= fun () ->
    or_error c "UDPv4" U.connect i
    >>= fun udp ->

    let dhcp, _offers = D.create (N.mac net) udp in
    or_error c "TCPv4" T.connect i
    >>= fun tcp ->

    N.listen net (
      E.input
        ~arpv4:(A.input a)
        ~ipv4:(
          I.input
            ~tcp:(
              T.input tcp ~listeners:
                (function
                  | 80 -> Some (fun flow ->
                      let dst, dst_port = T.dst flow in
                      C.log_s c
                        (green "new tcp from %s %d"
                          (Ipaddr.V4.to_string dst) dst_port
                        )
                      >>= fun () ->

                      T.read flow
                      >>= function
                      | `Ok b ->
                        C.log_s c
                          (yellow "read: %d\n%s"
                            (Cstruct.len b) (Cstruct.to_string b)
                          )
                        >>= fun () ->
                        T.close flow
                      | `Eof -> C.log_s c (red "read: eof")
                      | `Error _e -> C.log_s c (red "read: error"))
                  | _ -> None
                ))
            ~udp:(
              U.input ~listeners:
                (fun ~dst_port ->
                   C.log c (blue "udp packet on port %d" dst_port);
                   D.listen dhcp ~dst_port)
                udp
            )
            ~default:(fun ~proto:_ ~src:_ ~dst:_ _ -> Lwt.return_unit)
            i
        )
        ~ipv6:(fun _b -> C.log_s c (yellow "ipv6")) e
    )
end
