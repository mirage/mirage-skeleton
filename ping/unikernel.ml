open Lwt
open V1_LWT

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let ipaddr   = "10.0.0.2"
let netmask  = "255.255.255.0"
let gateways = ["10.0.0.1"]

module Main (C:CONSOLE) (N:NETWORK) = struct

  module E = Ethif.Make(N)
  module I = Ipv4.Make(E)

  let or_error c name fn t =
    fn t
    >>= function
    | `Error e -> fail (Failure ("Error starting " ^ name))
    | `Ok t -> return t

  let start c n =
    C.log c (green "starting...");
    or_error c "Ethif" E.connect n >>= fun e ->
    or_error c "Ipv4"  I.connect e >>= fun i ->

    I.set_ip i (Ipaddr.V4.of_string_exn ipaddr) >>= fun () ->
    I.set_ip_netmask i (Ipaddr.V4.of_string_exn netmask) >>= fun () ->
    I.set_ip_gateways i (List.map Ipaddr.V4.of_string_exn gateways)
    >>= fun () ->

    let handler s = fun ~src ~dst data ->
      C.log_s c (yellow "%s > %s TCP"
                   (Ipaddr.V4.to_string src) (Ipaddr.V4.to_string dst))
    in
    N.listen n
      (E.input
         ~arpv4:(I.input_arpv4 i)
         ~ipv4:(I.input
                  ~tcp:(handler "TCP")
                  ~udp:(handler "UDP")
                  ~default:(fun ~proto ~src ~dst data ->
                      C.log_s c (red "%d DEFAULT" proto))
                  i
               )
         ~ipv6:(fun buf -> return (C.log c (red "IP6")))
         e)
    >>= fun () ->
    C.log c (green "done!");
    return ()

end
