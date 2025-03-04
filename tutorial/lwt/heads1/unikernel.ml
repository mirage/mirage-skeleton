open Lwt.Infix

let start () =
  Lwt.join
    [
      ( Mirage_sleep.ns (Duration.of_sec 1) >|= fun () ->
        Logs.info (fun m -> m "Heads") );
      ( Mirage_sleep.ns (Duration.of_sec 2) >|= fun () ->
        Logs.info (fun m -> m "Tails") );
    ]
  >|= fun () -> Logs.info (fun m -> m "Finished")
