open Mirage

let main =
  foreign
    ~libraries:["duration"] ~packages:["duration"]
    "Unikernel.Main" (time @-> console @-> job)

let () = register "io_page" [
  main $ default_time $ default_console
]
