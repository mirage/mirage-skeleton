(* mirage >= 4.9.0 & < 4.11.0 *)
open Mirage

let packages = [ package "duration" ]
let main = main ~packages "Unikernel" job
let () = register "hello-key" [ main ]
