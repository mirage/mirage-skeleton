(* mirage >= 4.7.0 & < 4.9.0 *)
open Mirage

let main =
  main "Unikernel.Main"
    (block @-> random @-> job)
    ~packages:[ package "checkseum"; package "cstruct"; package "fmt" ]

let img =
  if_impl Key.is_solo5 (block_of_file "storage") (block_of_file "disk.img")

let () = register "lottery" [ main $ img $ default_random ]
