open Lwt
open V1_LWT

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let ipaddr   = "fc00::2"
let gateways = ["fc00::1"]

module Main (C:CONSOLE) (N:NETWORK) (Clock : V1.CLOCK) (Time : TIME) = struct

  module E = Ethif.Make(N)
  module I = Ipv6.Make(E)(Time)(Clock)

  let or_error c name fn t =
    fn t
    >>= function
    | `Error e -> fail (Failure ("Error starting " ^ name))
    | `Ok t -> return t

  let start c n _clock _time =
    C.log c (green "starting...");
    or_error c "Ethif" E.connect n >>= fun e ->
    or_error c "Ipv6"  I.connect e >>= fun i ->

    I.set_ip i (Ipaddr.V6.of_string_exn ipaddr) >>= fun () ->
    I.set_ip_gateways i (List.map Ipaddr.V6.of_string_exn gateways) >>= fun () ->

    let handler s = fun ~src ~dst data ->
      C.log_s c (yellow "%s > %s %s"
                   (Ipaddr.V6.to_string src) (Ipaddr.V6.to_string dst) s)
    in
    N.listen n
      (E.input
         ~arpv4:(fun _ -> return (C.log c (red "ARP4")))
         ~ipv4:(fun _ -> return (C.log c (red "IP4")))
         ~ipv6:(I.input
                  ~tcp:(handler "TCP")
                  ~udp:(handler "UDP")
                  ~default:(fun ~proto ~src ~dst data ->
                      C.log_s c (red "%d DEFAULT" proto))
                  i
               )
         e)
    >>= fun () ->
    C.log c (green "done!");
    return ()

end
