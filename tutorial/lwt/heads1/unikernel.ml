open Lwt.Infix

let start _time =
  Lwt.join
    [
      ( Mirage_time.sleep_ns (Duration.of_sec 1) >|= fun () ->
        Logs.info (fun m -> m "Heads") );
      ( Mirage_time.sleep_ns (Duration.of_sec 2) >|= fun () ->
        Logs.info (fun m -> m "Tails") );
    ]
  >|= fun () -> Logs.info (fun m -> m "Finished")
