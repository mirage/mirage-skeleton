(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  main
    ~packages:[ package "duration"; package "randomconv" ]
    "Unikernel.Heads2" (time @-> job)

let () = register "heads2" [ main $ default_time ]
