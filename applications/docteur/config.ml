open Mirage

let filename =
  let doc = Key.Arg.info ~doc:"The filename to print out." [ "filename" ] in
  Key.(create "filename" Arg.(required string doc))

let unikernel = foreign "Unikernel.Make" ~keys:[ Key.v filename ] (kv_ro @-> job)
(* dotgit is a symlink to ../../.git. See https://github.com/mirage/mirage/issues/1445 for a discussion *)
let remote = "relativize://dotgit"

let () =
  register "static_kv_ro"
    [ unikernel $ docteur ~branch:"refs/heads/main" remote ]
