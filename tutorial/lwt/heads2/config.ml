open Mirage

let main =
  main
    ~packages:[package "duration"; package "randomconv"]
    "Unikernel.Heads2" (console @-> time @-> job)

let () =
  register "heads2" [ main $ default_console $ default_time ]
