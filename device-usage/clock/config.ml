(* mirage >= 4.4.0 & < 4.9.0 *)
open Mirage

let main =
  let packages = [ package "duration" ] in
  main ~packages ~deps:[ dep noop ] "Unikernel" job

let () =
  register "speaking_clock" [ main ]
