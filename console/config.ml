open Mirage

let main =
  foreign "Unikernel.Main" (console @-> job)

let () =
  register "console" [main $ default_console]
