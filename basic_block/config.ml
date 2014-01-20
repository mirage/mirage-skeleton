open Mirage

let () =
  let main =
    foreign "Block_test.Main"
      (console @-> block @-> job)
  in
  let block = block_of_file "disk.raw" in
  register "basic_block" [
    main $ default_console $ block
  ]
