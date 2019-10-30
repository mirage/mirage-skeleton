open Lwt.Infix

module Hello (Time : Mirage_time.S) = struct

  let start _time =

    let hello = Key_gen.hello () in

    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        Logs.info (fun f -> f "%s" hello);
        Time.sleep_ns (Duration.of_sec 1) >>= fun () ->
        loop (n-1)
    in
    loop 4

end
