open Mirage

let () =
  let main = foreign "Unikernel.Block_test" (console @-> block @-> job) in
  let img = block_of_file "disk.img" in
  register "block_test" [main $ default_console $ img]
