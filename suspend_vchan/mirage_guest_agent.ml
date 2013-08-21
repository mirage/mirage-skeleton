open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)
open Printf

module V = Vchan.Make(Xs)

let suspend () =
  lwt cancelled = Sched.suspend () in
  Console.log (Printf.sprintf "cancelled=%d" cancelled);
  Lwt.return cancelled

let control_watch () =
  let evtchn_h = Eventchn.init () in
  let buf = String.create 4096 in
  V.server ~blocking:true ~evtchn_h ~domid:0 ~xs_path:"data/vchan"
    ~read_size:4096 ~write_size:4096 ~persist:true >>= fun vch ->
  Xs.make () >>= fun xsh ->
  let rec inner () =
    V.read_into vch buf 0 4096 >>= fun nb_read ->
    let msg = String.sub buf 0 (nb_read-1) in
    (match msg with
    | "suspend" ->
      lwt _ = suspend () in
      lwt () = Console.log_s "About to read domid" in
      lwt domid = Xs.(immediate xsh (fun h -> read h "domid")) in
      lwt () = Console.log_s (Printf.sprintf "We're back: domid=%s" domid) in
      return true
    | "poweroff" ->
      Sched.shutdown Sched.Poweroff;
      return false (* Doesn't get here! *)
    | "reboot" ->
      Sched.shutdown Sched.Reboot;
      return false (* Doesn't get here! *)
    | "halt" ->
      Sched.shutdown Sched.Poweroff;
      return false
    | "crash" ->
      Sched.shutdown Sched.Crash;
      return false
    | _ ->
      return false)
    >>= fun ret ->
    V.write vch (Printf.sprintf "Done executing %s, ret = %b\n" msg ret) >>= fun () ->
    inner ()
  in inner ()

