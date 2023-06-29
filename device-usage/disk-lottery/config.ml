open Mirage

let reset_all =
  let doc =
    Key.Arg.info ~doc:"Reset all state on disk and quit" [ "reset-all" ]
  in
  Key.(create "reset-all" (Arg.flag ~stage:`Run doc))

let sector =
  let doc =
    Key.Arg.info ~doc:"Sector to read and write game state to" [ "slot" ]
  in
  Key.(create "sector" (Arg.opt ~stage:`Run Arg.int64 0L doc))

let reset =
  let doc =
    Key.Arg.info
      ~doc:
        "Reset the state on disk at the specified slot (using --slot, default \
         0) and quit"
      [ "reset" ]
  in
  Key.(create "reset" (Arg.flag ~stage:`Run doc))

let main =
  main "Unikernel.Main"
    (block @-> random @-> job)
    ~keys:[ key reset_all; key reset; key sector ]
    ~packages:[ package "checkseum"; package "cstruct"; package "fmt" ]

let img =
  if_impl Key.is_solo5 (block_of_file "storage") (block_of_file "disk.img")

let () = register "lottery" [ main $ img $ default_random ]
