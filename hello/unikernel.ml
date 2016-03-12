open Lwt

module Main (C: V1_LWT.CONSOLE) = struct

  let start c =
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        C.log c (Key_gen.hello ());
        OS.Time.sleep 1.0 >>= fun () ->
        loop (n-1)
    in
    loop 4

end
