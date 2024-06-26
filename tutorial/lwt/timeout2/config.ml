(* mirage >= 4.4.0 & < 4.7.0 *)
open Mirage

let main =
  main
    ~packages:[ package "duration"; package ~max:"0.2.0" "randomconv" ]
    "Unikernel.Timeout2"
    (time @-> random @-> job)

let () = register "timeout2" [ main $ default_time $ default_random ]
