open Mirage

let main = foreign "Unikernel.Main" (console @-> block @-> job)

let img =
  if_impl Key.is_xen
    (block_of_file "xvda1")
    (block_of_file "disk.img")

let () =
  register "block_test" [main $ default_console $ img]
