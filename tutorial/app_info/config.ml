(* mirage >= 4.4.0 & < 4.9.0 *)
open Mirage

let main =
  main "Unikernel"
    ~packages:[ package "fmt"; package "dune-build-info" ]
    job

let () = register "app-info" [ main ]
