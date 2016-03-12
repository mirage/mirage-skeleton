open Lwt.Infix

module Main (C: V1_LWT.CONSOLE) = struct

  let start c =
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        C.log c "hello";
        OS.Time.sleep 1.0 >>= fun () ->
        C.log c "world";
        loop (n-1)
    in
    loop 4

end
