(* mirage >= 4.7.0 & < 4.8.0 *)
open Mirage

let main =
  main
    ~packages:[ package "duration"; package ~min:"0.2.0" "randomconv" ]
    "Unikernel.Timeout1"
    (time @-> random @-> job)

let () = register "timeout1" [ main $ default_time $ default_random ]
