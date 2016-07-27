open Mirage

let main =
  foreign
    ~libraries:["duration"] ~packages:["duration"]
    "Unikernel.Main" (console @-> job)

let () = register "io_page" [
  main $ default_console
]
