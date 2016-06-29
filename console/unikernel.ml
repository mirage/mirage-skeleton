open Lwt.Infix

module Main (C: V1_LWT.CONSOLE) = struct

  let start c =
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        C.log_s c "hello" >>= fun () ->
        OS.Time.sleep_ns 1_000_000_000L >>= fun () ->
        C.log_s c "world" >>= fun () ->
        loop (n-1)
    in
    loop 4

end
