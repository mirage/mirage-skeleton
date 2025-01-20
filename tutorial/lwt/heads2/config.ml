(* mirage >= 4.4.0 & < 4.9.0 *)
open Mirage

let main =
  main
    ~packages:[ package "duration"; package ~min:"0.2.0" "randomconv" ]
    ~deps:[ dep noop ]
    "Unikernel" job

let () = register "heads2" [ main ]
