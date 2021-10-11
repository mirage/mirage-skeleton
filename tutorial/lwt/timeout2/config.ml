open Mirage

let main =
  main
    ~packages:[ package "duration"; package "randomconv" ]
    "Unikernel.Timeout2"
    (console @-> time @-> random @-> job)

let () =
  register "timeout2" [ main $ default_console $ default_time $ default_random ]
