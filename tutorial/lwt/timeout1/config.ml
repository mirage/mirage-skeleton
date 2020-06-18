open Mirage

let main =
  main
    ~packages:[package "duration"; package "randomconv"]
    "Unikernel.Timeout1" (console @-> time @-> random @-> job)

let () =
  register "timeout1" [ main $ default_console $ default_time $ default_random ]
