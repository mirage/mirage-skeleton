open Mirage

let () =
  register "console" [
    foreign "Hello.Main" (console @-> job) $ default_console
  ]
