open OS
open Lwt.Infix

module Heads2 (C: Mirage_types_lwt.CONSOLE) = struct

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
