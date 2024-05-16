(* mirage >= 4.5.0 & < 4.6.0 *)
open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.filename" ]
let unikernel = main ~runtime_args "Unikernel.Make" (kv_ro @-> job)
let remote = "https://github.com/mirage/mirage"

let () =
  register "docteur_kv_ro"
    [ unikernel $ docteur ~branch:"refs/heads/main" remote ]
