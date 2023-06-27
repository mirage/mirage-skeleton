open Mirage

let main = main "Unikernel.Main" (block @-> job)

let img =
  if_impl Key.is_solo5 (block_of_file "storage") (block_of_file "disk.img")

let () = register "block_test" [ main $ img ]
