open V1_LWT
open Lwt
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

let packets_in = ref 0l
let packets_waiting = ref 0l

module Main (C: CONSOLE)(N1: NETWORK)(N2: NETWORK) = struct

  module E = Ethif.Make(N1)

  let or_error c name fn t =
  fn t
    >>= function
    | `Error e -> fail (Failure ("error starting " ^ name))
    | `Ok t -> C.log_s c (green "%s connected." name) >>
               return t

  let (in_queue, in_push) = Lwt_stream.create ()
  let (out_queue, out_push) = Lwt_stream.create ()

  let listen nf =
    let hw_addr =  Macaddr.to_string (E.mac nf) in
    let _ = printf "listening on the interface with mac address '%s' \n%!" hw_addr in
    N1.listen (E.id nf) (fun frame -> return (in_push (Some frame)))

  let update_packet_count () =
    let _ = packets_in := Int32.succ !packets_in in
    let _ = packets_waiting := Int32.succ !packets_waiting in
    if (Int32.logand !packets_in 0xfl) = 0l then
        let _ = printf "packets (in = %ld) (not forwarded = %ld)" !packets_in !packets_waiting in 
        print_endline ""

  let start console n1 n2 =

    let forward_thread nf =
      while_lwt true do
        lwt _ = Lwt_stream.next in_queue >>= fun frame -> return (out_push (Some frame)) in
        return (update_packet_count ())
      done  
      <?> (
      while_lwt true do
        lwt frame = Lwt_stream.next out_queue in
          let _ = packets_waiting := Int32.pred !packets_waiting in
          E.write nf frame
      done
      )
  in
  lwt nf1 = or_error console "interface" E.connect n1 in
  lwt nf2 = or_error console "interface" E.connect n2 in
  (listen nf1) <?> (forward_thread nf2)
  >> return (print_endline "terminated.")

end
