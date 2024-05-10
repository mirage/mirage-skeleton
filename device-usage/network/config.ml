(* mirage >= 4.5.0 & < 4.6.0 *)
open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.port" ]
let main = main ~runtime_args "Unikernel.Main" (stackv4v6 @-> job)
let stack = generic_stackv4v6 default_network
let () = register "network" [ main $ stack ]
