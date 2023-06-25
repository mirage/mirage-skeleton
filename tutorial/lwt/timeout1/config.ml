open Mirage

let main =
  main
    ~packages:[ package "duration"; package "randomconv" ]
    "Unikernel.Timeout1"
    (time @-> random @-> job)

let () = register "timeout1" [ main $ default_time $ default_random ]
