open Lwt.Infix

let start () =
  let heads =
    Mirage_sleep.ns (Duration.of_sec 1) >|= fun () ->
    Logs.info (fun m -> m "Heads")
  in
  let tails =
    Mirage_sleep.ns (Duration.of_sec 2) >|= fun () ->
    Logs.info (fun m -> m "Tails")
  in
  heads <&> tails >|= fun () -> Logs.info (fun m -> m "Finished")
