open Lwt.Infix

module Main (C: V1_LWT.CONSOLE) (T: V1_LWT.TIME) = struct

  let start c =
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        C.log_s c "hello" >>= fun () ->
        Time.sleep 1.0 >>= fun () ->
        C.log_s c "world" >>= fun () ->
        loop (n-1)
    in
    loop 4

end
