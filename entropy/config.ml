open Mirage

let main = foreign "Unikernel.Main" (console @-> entropy @-> job)

let () =
  register "console" [
    main $ default_console $ default_entropy
  ]
