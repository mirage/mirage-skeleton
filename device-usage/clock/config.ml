(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  let extra_deps = [ dep default_time ] in
  let packages = [ package "duration" ] in
  main ~extra_deps ~packages "Unikernel.Main" (pclock @-> mclock @-> job)

let () =
  register "speaking_clock"
    [ main $ default_posix_clock $ default_monotonic_clock ]
