(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  let packages = [ package "duration" ] in
  main ~packages "Unikernel.Main" (time @-> pclock @-> mclock @-> job)

let () =
  register "speaking_clock"
    [ main $ default_time $ default_posix_clock $ default_monotonic_clock ]
