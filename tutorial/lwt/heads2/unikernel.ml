open Lwt.Infix

let start _time =
  let heads =
    Mirage_time.sleep_ns (Duration.of_sec 1) >|= fun () ->
    Logs.info (fun m -> m "Heads")
  in
  let tails =
    Mirage_time.sleep_ns (Duration.of_sec 2) >|= fun () ->
    Logs.info (fun m -> m "Tails")
  in
  heads <&> tails >|= fun () -> Logs.info (fun m -> m "Finished")
