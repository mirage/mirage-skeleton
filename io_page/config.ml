open Mirage

let main =
  foreign
    ~libraries:["duration"; "io-page"] ~packages:["duration"; "io-page"]
    "Unikernel.Main" (time @-> console @-> job)

let () = register "io_page" [
  main $ default_time $ default_console
]
