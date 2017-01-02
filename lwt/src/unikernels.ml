open OS
open Lwt.Infix

module Heads1 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep_ns (Duration.of_sec 1) >>= fun () -> C.log c "Heads");
      (Time.sleep_ns (Duration.of_sec 2) >>= fun () -> C.log c "Tails")
    ] >>= fun () ->
    C.log c "Finished"

end

module Heads2 (C: V1_LWT.CONSOLE) = struct

  let start c =
    let heads =
      Time.sleep_ns (Duration.of_sec 1) >>= fun () -> C.log c "Heads"
    in
    let tails =
      Time.sleep_ns (Duration.of_sec 2) >>= fun () -> C.log c "Tails"
    in
    (heads <&> tails) >>= fun () ->
    C.log c "Finished"

end

module Timeout1 (C: V1_LWT.CONSOLE) (R: V1_LWT.RANDOM) = struct

  let timeout delay t =
    Time.sleep_ns delay >>= fun () ->
    match Lwt.state t with
    | Lwt.Sleep    -> Lwt.cancel t; Lwt.return None
    | Lwt.Return v -> Lwt.return (Some v)
    | Lwt.Fail ex  -> Lwt.fail ex

  let start c _r =
    let t =
      Time.sleep_ns (Duration.of_ms (Randomconv.int ~bound:3000 R.generate))
      >|= fun () -> "Heads"
    in
    timeout (Duration.of_sec 2) t >>= function
    | None   -> C.log c "Cancelled"
    | Some v -> C.log c (Printf.sprintf "Returned %S" v)

end

module Timeout2 (C: V1_LWT.CONSOLE) (R: V1_LWT.RANDOM) = struct

  let timeout delay t =
    let tmout = Time.sleep_ns delay in
    Lwt.pick [
      (tmout >|= fun () -> None);
      (t >|= fun v -> Some v);
    ]

  let start c _r =
    let t =
      Time.sleep_ns (Duration.of_ms (Randomconv.int ~bound:3000 R.generate))
      >|= fun () -> "Heads"
    in
    timeout (Duration.of_sec 2) t >>= function
    | None   -> C.log c "Cancelled"
    | Some v -> C.log c (Printf.sprintf "Returned %S" v)

end

module Echo_server1 (C: V1_LWT.CONSOLE) (R: V1_LWT.RANDOM) = struct

  let read_line () =
    OS.Time.sleep_ns (Duration.of_ms (Randomconv.int ~bound:2500 R.generate))
    >|= fun () ->
    String.make (Randomconv.int ~bound:20 R.generate) 'a'

  let start c _r =
    let rec echo_server = function
      | 0 -> Lwt.return ()
      | n ->
        read_line () >>= fun s ->
        C.log c s >>= fun () ->
        echo_server (n - 1)
    in
    echo_server 10

end
