(* mirage >= 4.9.0 & < 4.11.0 *)
open Mirage

let main =
  let packages = [ package "duration" ] in
  main ~packages "Unikernel" job

let () = register "speaking_clock" [ main ]
