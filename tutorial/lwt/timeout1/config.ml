(* mirage >= 4.9.0 & < 4.10.0 *)
open Mirage

let main =
  main
    ~packages:[ package "duration"; package ~min:"0.2.0" "randomconv" ]
    "Unikernel"
    job

let () = register "timeout1" [ main ]
