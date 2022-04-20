open Mirage

let filename =
  let doc = Key.Arg.info ~doc:"The filename to print out." [ "filename" ] in
  Key.(create "filename" Arg.(required string doc))

let unikernel =
  foreign "Unikernel.Make" ~keys:[ Key.v filename ] (console @-> kv_ro @-> job)

let console = default_console
let remote = "https://github.com/mirage/mirage"

let () =
  register "static_kv_ro"
    [ unikernel $ console $ docteur ~branch:"refs/heads/main" remote ]
