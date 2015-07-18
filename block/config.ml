open Mirage

let main = foreign "Unikernel.Main" (console @-> block @-> job)

let img = match get_mode () with
  | `Xen -> block_of_file "xvda1"
  | `Unix | `MacOSX -> block_of_file "disk.img"

let () =
  register "block_test" [main $ default_console $ img]
