(* mirage >= 4.5.0 & < 4.9.0 *)
open Mirage

let packages = [ package "duration" ]
let main = main ~packages "Unikernel.Hello" (time @-> job)
let () = register "hello-key" [ main $ default_time ]
