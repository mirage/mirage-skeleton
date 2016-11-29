open Mirage

let main =
  foreign
    ~packages:[package "duration"; package "io-page"]
    "Unikernel.Main" (time @-> console @-> job)

let () = register "io_page" [
  main $ default_time $ default_console
]
