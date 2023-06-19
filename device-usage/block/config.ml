open Mirage

let main =
  let packages =
    [
      package "io-page";
      package "duration";
    ]
  in
  main ~packages "Unikernel.Main" (block @-> job)

let img =
  Key.(if_impl is_solo5 (block_of_file "storage") (block_of_file "disk.img"))

let () = register "block_test" [ main $ img ]
