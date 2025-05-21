open Lwt.Infix
open Cmdliner

let hello =
  let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
  Mirage_runtime.register_arg Arg.(value & opt string "Hello World!" doc)

let start () =
  let rec loop = function
    | 0 -> Lwt.return_unit
    | n ->
        Logs.info (fun f -> f "%s" (hello ()));
        Mirage_sleep.ns (Duration.of_sec 1) >>= fun () -> loop (n - 1)
  in
  loop 4
