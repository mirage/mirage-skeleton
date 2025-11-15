(* mirage >= 4.10.0 & < 4.11.0 *)
open Mirage

let main = main "Unikernel.Main" (block @-> job)

let img =
  if_impl Key.is_solo5 (block_of_file "storage")
    (if_impl Key.is_unikraft (block_of_file "0") (block_of_file "disk.img"))

let () = register "block_test" [ main $ img ]
