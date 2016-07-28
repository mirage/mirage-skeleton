open Mirage

let main = foreign "Unikernel.Main" (time @-> console @-> job)

let () = register "io_page" [
  main $ default_time $ default_console
]
