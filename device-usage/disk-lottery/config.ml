(* mirage >= 4.9.0 & < 4.10.0 *)
open Mirage

let main =
  main "Unikernel.Main" (block @-> job)
    ~packages:[ package "checkseum"; package "cstruct"; package "fmt" ]

let img =
  if_impl Key.is_solo5 (block_of_file "storage") (block_of_file "disk.img")

let () = register "lottery" [ main $ img ]
