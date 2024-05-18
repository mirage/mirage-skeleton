open Lwt.Infix
open Cmdliner

let hello =
  let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
  Arg.(value & opt string "Hello World!" doc)

let start () hello =
  let rec loop = function
    | 0 -> Lwt.return_unit
    | n ->
      Logs.info (fun f -> f "%s" hello);
      Mirage_time.sleep_ns (Duration.of_sec 1) >>= fun () -> loop (n - 1)
  in
  loop 4
