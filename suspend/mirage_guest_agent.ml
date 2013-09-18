open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)
open Printf

let suspend () =
  lwt cancelled = Sched.suspend () in
  Console.log (Printf.sprintf "cancelled=%d" cancelled);
  Lwt.return cancelled

let control_watch () = 
  lwt () = Console.log_s (Printf.sprintf "xs_watch ()") in
  lwt xsc = Xs.make () in
  let rec inner () = 
    lwt dir = Xs.(immediate xsc (fun h -> directory h "control")) in
    lwt result =
      if List.mem "shutdown" dir then begin
      lwt msg = try_lwt Xs.(immediate xsc (fun h -> read h "control/shutdown")) with _ -> return "" in
      lwt () = Console.log_s (Printf.sprintf "Got control message: %s" msg) in
      match msg with
      | "suspend" -> 
          lwt () = Xs.(immediate xsc (fun h -> rm h "control/shutdown")) in
          lwt _ = suspend () in
          lwt () = Console.log_s "About to read domid" in
          lwt domid = Xs.(immediate xsc (fun h -> read h "domid")) in
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
          return false
      end else return false
    in
    lwt () = Time.sleep 1.0 in
    inner ()
  in inner ()

