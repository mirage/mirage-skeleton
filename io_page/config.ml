open Mirage

let main = foreign "Unikernel.Main" (console @-> job)

let () = register "io_page" [
  main $ default_console
]
