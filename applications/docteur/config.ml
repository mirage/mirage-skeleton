open Mirage

let filename =
  let doc = Key.Arg.info ~doc:"The filename to print out." [ "filename" ] in
  Key.(create "filename" Arg.(required ~stage:`Run string doc))

let unikernel = foreign "Unikernel.Make" ~keys:[ Key.v filename ] (kv_ro @-> job)
let remote = "https://github.com/mirage/mirage"

let () =
  register "static_kv_ro"
    [ unikernel $ docteur ~branch:"refs/heads/main" remote ]
