open Lwt.Infix

module Heads2 (C: Mirage_console.S) (Time: Mirage_time.S) = struct

  let start c _time =
    let heads =
      Time.sleep_ns (Duration.of_sec 1) >>= fun () -> C.log c "Heads"
    in
    let tails =
      Time.sleep_ns (Duration.of_sec 2) >>= fun () -> C.log c "Tails"
    in
    (heads <&> tails) >>= fun () ->
    C.log c "Finished"

end
