open Mirage

let main =
  foreign "Unikernel.Main" (console @-> pclock @-> job)

let () =
  register "speaking_clock" [ main $ default_console $ default_posix_clock ]
