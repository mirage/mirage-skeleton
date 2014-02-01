open Mirage

let main = foreign "Hello.Main" (console @-> job)

let () =
  register "console" [
    main $ default_console
  ]
