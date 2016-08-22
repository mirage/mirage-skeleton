open Mirage

let main =
  foreign "Unikernel.Main" (console @-> time @-> pclock @-> mclock @-> job)

let () =
  register "speaking_clock" [ main $ default_console $ default_time $ default_posix_clock $ default_monotonic_clock ]
