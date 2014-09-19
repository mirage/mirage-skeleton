open Mirage

let main = foreign "Unikernel.Main" (console @-> job)

let () =
  register "grant" [
    main $ default_console
  ]
