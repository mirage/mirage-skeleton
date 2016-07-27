open Mirage

let main =
  foreign
    ~libraries:["duration"] ~packages:["duration"]
    "Unikernel.Main" (console @-> time @-> job)

let () =
  register "console" [main $ default_console $ default_time ]
