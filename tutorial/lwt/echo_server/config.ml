(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  let packages = [ package "duration"; package ~max:"0.2.0" "randomconv" ] in
  let extra_deps = [ dep default_time ] in
  main ~extra_deps ~packages "Unikernel.Echo_server" (random @-> job)

let () = register "echo_server" [ main $ default_random ]
