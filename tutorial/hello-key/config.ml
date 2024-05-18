(* mirage >= 4.5.0 & < 4.6.0 *)
open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.hello" ]
let packages = [ package "duration" ]
let extra_deps = [ dep default_time ]
let main = main ~extra_deps ~runtime_args ~packages "Unikernel" job
let () = register "hello-key" [ main ]
