(* mirage >= 4.7.0 & < 4.9.0 *)
open Mirage

let main =
  let packages = [ package "duration"; package ~min:"0.2.0" "randomconv" ] in
  main ~packages "Unikernel" job

let () = register "echo_server" [ main ]
