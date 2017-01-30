open OS
open Lwt.Infix

module Heads1 (C: Mirage_types_lwt.CONSOLE) = struct

  let start c =
    Lwt.join [
      (Time.sleep_ns (Duration.of_sec 1) >>= fun () -> C.log c "Heads");
      (Time.sleep_ns (Duration.of_sec 2) >>= fun () -> C.log c "Tails")
    ] >>= fun () ->
    C.log c "Finished"

end
