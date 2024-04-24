open Mirage

let main =
  main ~extra_deps:[ dep default_time ; dep default_monotonic_clock ]
    "Unikernel.Main" (job @-> job)

let () = register "speaking_clock" [ main $ noop ]
