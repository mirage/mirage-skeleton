(* mirage >= 4.5.0 & < 4.8.0 *)
open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.hello" ]
let packages = [ package "duration" ]
let main = main ~runtime_args ~packages "Unikernel.Hello" (time @-> job)
let () = register "hello-key" [ main $ default_time ]
