open Lwt.Infix

module Heads1 (C: Mirage_console_lwt.S) (Time: Mirage_time_lwt.S) = struct

  let start c _time =
    Lwt.join [
      (Time.sleep_ns (Duration.of_sec 1) >>= fun () -> C.log c "Heads");
      (Time.sleep_ns (Duration.of_sec 2) >>= fun () -> C.log c "Tails")
    ] >>= fun () ->
    C.log c "Finished"

end
