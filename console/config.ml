open Mirage

let main =
  foreign
    ~libraries:["duration"] ~packages:["duration"]
    "Unikernel.Main" (console @-> job)

let () =
  register "console" [main $ default_console]
