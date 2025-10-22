(* mirage >= 4.10.0 & < 4.11.0 *)
open Mirage

let unikernel =
  main "Unikernel.Make"
    ~packages:[ package "hxd" ~sublibs:[ "core"; "string" ] ]
    (kv_rw @-> job)

let block = block_of_file "littlefs"
let program_block_size =
  Runtime_arg.create ~pos:__POS__ "Unikernel.program_block_size"
let fs = chamelon ~program_block_size block
let () = register "elittlefs" [ unikernel $ fs ]
