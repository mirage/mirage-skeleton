(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  let extra_deps = [ dep default_time ] in
  main ~extra_deps ~packages:[ package "duration" ] "Unikernel" job

let () = register "heads1" [ main ]
