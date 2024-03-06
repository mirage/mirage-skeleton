open Lwt.Infix
open Cmdliner

let hello =
  let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
  let key = Arg.(value & opt string "Hello World!" doc) in
  Mirage_runtime.register key

module Hello (Time : Mirage_time.S) = struct
  let start _time =
    let hello = hello () in

    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
          Logs.info (fun f -> f "%s" hello);
          Time.sleep_ns (Duration.of_sec 1) >>= fun () -> loop (n - 1)
    in
    loop 4
end
