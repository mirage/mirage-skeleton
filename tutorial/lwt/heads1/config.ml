(* mirage >= 4.4.0 & < 4.9.0 *)
open Mirage

let main =
  main ~packages:[ package "duration" ] ~deps:[ dep noop ] "Unikernel" job

let () = register "heads1" [ main ]
