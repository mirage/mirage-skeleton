open Mirage

let main =
  main
    ~packages:[ package "duration"; package "randomconv" ]
    "Unikernel.Timeout2"
    (time @-> random @-> job)

let () = register "timeout2" [ main $ default_time $ default_random ]
