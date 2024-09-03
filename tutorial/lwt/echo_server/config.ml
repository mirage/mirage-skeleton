(* mirage >= 4.4.0 & < 4.7.0 *)
open Mirage

let main =
  let packages = [ package "duration"; package "randomconv" ] in
  main ~packages "Unikernel.Echo_server" (time @-> random @-> job)

let () = register "echo_server" [ main $ default_time $ default_random ]
