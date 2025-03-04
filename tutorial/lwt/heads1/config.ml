(* mirage >= 4.9.0 & < 4.10.0 *)
open Mirage

let main =
  main ~packages:[ package "duration" ] "Unikernel" job

let () = register "heads1" [ main ]
