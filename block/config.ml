open Mirage

let main = foreign "Unikernel.Main" (console @-> block @-> job)

let img = block_of_file "disk.img"

let () =
  register "block_test" [main $ default_console $ img]
