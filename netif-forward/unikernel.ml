open Mirage_types_lwt
open Lwt.Infix

let packets_in = ref 0l
let packets_waiting = ref 0l

module Main (C: CONSOLE)(N1: NETWORK)(N2: NETWORK) = struct

  let (in_queue, in_push) = Lwt_stream.create ()
  let (out_queue, out_push) = Lwt_stream.create ()

  let listen c nf =
    let hw_addr =  Macaddr.to_string (N1.mac nf) in
    C.log c (Printf.sprintf "listening on the interface with mac address '%s'" hw_addr) >>= fun () ->
    N1.listen nf (fun frame -> Lwt.return (in_push (Some frame))) >|= Rresult.R.get_ok

  let update_packet_count c () =
    let _ = packets_in := Int32.succ !packets_in in
    let _ = packets_waiting := Int32.succ !packets_waiting in
    if (Int32.logand !packets_in 0xfl) = 0l then
      Lwt.async (fun () ->
          C.log c (Printf.sprintf "packets (in = %ld) (not forwarded = %ld)"
                     !packets_in !packets_waiting))

  let start console n1 n2 =
    let forward_thread c nf =
      let rec inq () =
        Lwt_stream.next in_queue >>= fun frame ->
        out_push (Some frame) ;
        update_packet_count c () ;
        inq ()
      in
      let rec outq () =
        Lwt_stream.next out_queue >>= fun frame ->
        packets_waiting := Int32.pred !packets_waiting ;
        N2.write nf frame >|= Rresult.R.get_ok >>=
        outq
      in
      (inq ()) <?> (outq ())
  in
  (listen console n1) <?> (forward_thread console n2) >>= fun () ->
  C.log console "terminated."

end
