open OS
open Lwt.Infix

module Heads1 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep 1.0 >|= fun () ->
       C.log c "Heads");
      (Time.sleep 2.0 >|= fun () ->
       C.log c "Tails");
    ] >|= fun () ->
    C.log c ("Finished")

end

module Heads2 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep 1.0 >|= fun () -> C.log c "Heads");
      (Time.sleep 2.0 >|= fun () -> C.log c "Tails");
    ] >|= fun () ->
    C.log c "Finished";

end

module Heads3 (C: V1_LWT.CONSOLE) = struct

  let start c =
    let heads =
      Time.sleep 1.0 >|= fun () ->
      C.log c "Heads"
    in
    let tails =
      Time.sleep 2.0 >|= fun () ->
      C.log c "Tails"
    in
    (heads <&> tails) >|= fun () ->
    C.log c "Finished"

end

module Timeout1 (C: V1_LWT.CONSOLE) = struct

  let start c =
    Random.self_init ();

    let timeout f t =
      Time.sleep f >>= fun () ->
      match Lwt.state t with
      | Lwt.Return v -> Lwt.return (Some v)
      | _            -> Lwt.cancel t; Lwt.return None
    in

    let t = Time.sleep (Random.float 3.0) >|= fun () -> "Heads" in
    timeout 2.0 t >>= fun v ->
    C.log c (match v with None -> "cancelled" | Some v -> v);
    C.log c "Finished";
    Lwt.return_unit

end

module Timeout2 (C: V1_LWT.CONSOLE) = struct

  let start c  =
    Random.self_init ();
    let timeout f t =
      let tmout = Time.sleep f in
      Lwt.pick [
        (tmout >|= fun () -> None);
        (t >|= fun v -> Some v);
      ]
    in
    let t = Time.sleep (Random.float 3.0) >|= fun () -> "Heads" in
    timeout 2.0 t >>= fun v ->
    C.log c (match v with None -> "Cancelled" | Some v -> v);
    C.log c "Finished";
    Lwt.return_unit

end

module Echo_server1 (C: V1_LWT.CONSOLE) = struct

  let start c =
    let read_line () =
      Time.sleep (Random.float 2.5)
      >|= fun () ->String.make (Random.int 20) 'a'
    in
    let rec echo_server = function
      | 0 -> Lwt.return ()
      | n ->
        read_line () >>= fun s ->
        C.log c s;
        echo_server (n-1)
    in
    echo_server 10

end
