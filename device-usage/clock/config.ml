open Mirage

let main =
  foreign "Unikernel.Main" (time @-> pclock @-> mclock @-> job)

let () =
  register "speaking_clock" [
    main $ default_time $ default_posix_clock $ default_monotonic_clock
  ]
