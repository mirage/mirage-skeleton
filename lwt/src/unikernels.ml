open OS
open Lwt.Infix

module Heads1 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep_ns 1_000_000_000L >|= fun () ->
       C.log_s c "Heads");
      (Time.sleep_ns 2_000_000_000L >|= fun () ->
       C.log_s c "Tails");
    ] >|= fun () ->
    C.log c ("Finished")

end

module Heads2 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep_ns 1_000_000_000L >|= fun () -> C.log c "Heads");
      (Time.sleep_ns 2_000_000_000L >|= fun () -> C.log c "Tails");
    ] >|= fun () ->
    C.log_s c "Finished";

end

module Heads3 (C: V1_LWT.CONSOLE) = struct

  let start c =
    let heads =
      Time.sleep_ns 1_000_000_000L >|= fun () ->
      C.log_s c "Heads"
    in
    let tails =
      Time.sleep_ns 2_000_000_000L >|= fun () ->
      C.log_s c "Tails"
    in
    (heads <&> tails) >|= fun () ->
    C.log_s c "Finished"

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

    let t = Time.sleep_ns (Int64.of_int (Random.int 3_000_000_000L)) >|= fun () -> "Heads" in
    timeout 2_000_000_000L t >>= fun v ->
    C.log_s c (match v with None -> "cancelled" | Some v -> v) >>= fun () ->
    C.log_s c "Finished" >>= fun () ->
    Lwt.return_unit

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
    let timeout f t =
      let tmout = Time.sleep_ns f in
      Lwt.pick [
        (tmout >|= fun () -> None);
        (t >|= fun v -> Some v);
      ]
    in
    let t = Time.sleep_ns (Int64.of_int (Random.int 3_000_000_000)) >|= fun () -> "Heads" in
    timeout 2_000_000_000L t >>= fun v ->
    C.log_s c (match v with None -> "Cancelled" | Some v -> v);
    C.log_s c "Finished";
    Lwt.return_unit

end

module Echo_server1 (C: V1_LWT.CONSOLE) = struct

  let start c =
    let read_line () =
      Time.sleep_ns (Int64.of_int (Random.int 2_500_000_000))
      >|= fun () ->String.make (Random.int 20) 'a'
    in
    let rec echo_server = function
      | 0 -> Lwt.return ()
      | n ->
	read_line () >>= fun s ->
	C.log_s c s >>= fun () ->
	echo_server (n - 1)
    in
    echo_server 10

end
