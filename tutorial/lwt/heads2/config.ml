(* mirage >= 4.4.0 & < 4.8.0 *)
open Mirage

let main =
  main
    ~packages:[ package "duration"; package ~min:"0.2.0" "randomconv" ]
    "Unikernel.Heads2" (time @-> job)

let () = register "heads2" [ main $ default_time ]
