open Lwt.Infix

module Main (C: V1_LWT.CONSOLE) (Time: V1_LWT.TIME) = struct

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
