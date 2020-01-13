open Lwt.Infix

module Main (C: Mirage_console.S) (Time: Mirage_time.S) = struct

  let start c _time =
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        C.log c "hello" >>= fun () ->
        Time.sleep_ns (Duration.of_sec 1) >>= fun () ->
        C.log c "world" >>= fun () ->
        loop (pred n)
    in
    loop 4

end
