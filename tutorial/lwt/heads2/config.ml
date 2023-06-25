open Mirage

let main =
  main
    ~packages:[ package "duration"; package "randomconv" ]
    "Unikernel.Heads2" (time @-> job)

let () = register "heads2" [ main $ default_time ]
