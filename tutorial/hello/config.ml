(* mirage >= 4.9.0 & < 4.12.0 *)
open Mirage

let main = main "Unikernel" job ~packages:[ package "duration" ]
let () = register "hello" [ main ]
