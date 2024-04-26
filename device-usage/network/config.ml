open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.port" ]
let stack = generic_stackv4v6 default_network
let main = main ~extra_deps:[ dep stack ] ~runtime_args "Unikernel" job
let () = register "network" [ main ]
