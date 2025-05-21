(* mirage >= 4.9.0 & < 4.10.0 *)
open Mirage

let main =
  main "Unikernel" ~packages:[ package "fmt"; package "dune-build-info" ] job

let () = register "app-info" [ main ]
