open OS
open Lwt.Infix

module Heads1 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep_ns (Duration.of_sec 1) >>= fun () -> C.log_s c "Heads");
      (Time.sleep_ns (Duration.of_sec 2) >>= fun () -> C.log_s c "Tails")
    ] >>= fun () ->
    C.log_s c ("Finished")

end

module Heads2 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep_ns (Duration.of_sec 1) >|= fun () -> C.log c "Heads");
      (Time.sleep_ns (Duration.of_sec 2) >|= fun () -> C.log c "Tails");
    ] >|= fun () ->
    C.log c "Finished";

end

module Heads3 (C: V1_LWT.CONSOLE) = struct

  let start c =
    let heads =
      Time.sleep_ns (Duration.of_sec 1) >|= fun () ->
      C.log c "Heads"
    in
    let tails =
      Time.sleep_ns (Duration.of_sec 2) >|= fun () ->
      C.log c "Tails"
    in
    (heads <&> tails) >|= fun () ->
    C.log c "Finished"

end

module Timeout1 (C: V1_LWT.CONSOLE) = struct

  let timeout delay t =
    Time.sleep_ns delay >>= fun () ->
    match Lwt.state t with
    | Lwt.Sleep    -> Lwt.cancel t; Lwt.return None
    | Lwt.Return v -> Lwt.return (Some v)
    | Lwt.Fail ex  -> Lwt.fail ex

  let start c =
    Random.self_init ();
    let t = Time.sleep_ns (Duration.of_ms (Random.int 3000)) >|= fun () -> "Heads" in
    timeout (Duration.of_sec 2) t >>= function
    | None   -> C.log_s c "Cancelled"
    | Some v -> C.log_s c (Printf.sprintf "Returned %S" v)

end

module Timeout2 (C: V1_LWT.CONSOLE) = struct

  let timeout delay t =
    let tmout = Time.sleep_ns delay in
    Lwt.pick [
      (tmout >|= fun () -> None);
      (t >|= fun v -> Some v);
    ]

  let start c  =
    Random.self_init ();
    let t = Time.sleep_ns (Duration.of_ms (Random.int 3000)) >|= fun () -> "Heads" in
    timeout (Duration.of_sec 2) t >>= function
    | None   -> C.log_s c "Cancelled"
    | Some v -> C.log_s c (Printf.sprintf "Returned %S" v)

end

module Echo_server1 (C: V1_LWT.CONSOLE) = struct

  let read_line () =
    OS.Time.sleep_ns (Duration.of_ms (Random.int 2500)) >|= fun () ->
    String.make (Random.int 20) 'a'

  let start c =
    let rec echo_server = function
      | 0 -> Lwt.return ()
      | n ->
	read_line () >>= fun s ->
	C.log_s c s >>= fun () ->
	echo_server (n - 1)
    in
    echo_server 10

end
