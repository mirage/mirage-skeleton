open Lwt.Infix

module Heads1 (Time : Mirage_time.S) = struct
  let start _time =
    Lwt.join
      [
        ( Time.sleep_ns (Duration.of_sec 1) >|= fun () ->
          Logs.info (fun m -> m "Heads") );
        ( Time.sleep_ns (Duration.of_sec 2) >|= fun () ->
          Logs.info (fun m -> m "Tails") );
      ]
    >|= fun () -> Logs.info (fun m -> m "Finished")
end
