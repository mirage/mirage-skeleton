(* mirage >= 4.5.0 & < 4.7.0 *)
open Mirage

let runtime_args =
  [
    runtime_arg ~pos:__POS__ "Unikernel.sector";
    runtime_arg ~pos:__POS__ "Unikernel.reset_all";
    runtime_arg ~pos:__POS__ "Unikernel.reset";
  ]

let main =
  main "Unikernel.Main" ~runtime_args
    (block @-> random @-> job)
    ~packages:[ package "checkseum"; package "cstruct"; package "fmt" ]

let img =
  if_impl Key.is_solo5 (block_of_file "storage") (block_of_file "disk.img")

let () = register "lottery" [ main $ img $ default_random ]
