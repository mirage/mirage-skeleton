open Lwt.Infix

module Heads2 (Time : Mirage_time.S) = struct
  let start _time =
    let heads =
      Time.sleep_ns (Duration.of_sec 1) >|= fun () ->
      Logs.info (fun m -> m "Heads")
    in
    let tails =
      Time.sleep_ns (Duration.of_sec 2) >|= fun () ->
      Logs.info (fun m -> m "Tails")
    in
    heads <&> tails >|= fun () -> Logs.info (fun m -> m "Finished")
end
