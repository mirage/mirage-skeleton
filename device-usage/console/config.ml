open Mirage

let main =
  foreign
    ~packages:[package "duration"]
    "Unikernel.Main" (console @-> time @-> job)

let () =
  register "console" [main $ default_console $ default_time ]
