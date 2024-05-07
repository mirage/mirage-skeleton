(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  let extra_deps = [ dep default_time ] in
  main ~extra_deps "Unikernel" job ~packages:[ package "duration" ]

let () = register "hello" [ main ]
