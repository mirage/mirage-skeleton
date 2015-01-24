open Mirage

let () =
  let main = foreign "Unikernel.Block_test" (console @-> block @-> job) in
  let img =     
    match get_mode () with
    | `Xen -> block_of_file "xvda1"
    | `Unix -> block_of_file "disk.img" in
  register "block_test" [main $ default_console $ img]
