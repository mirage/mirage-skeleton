open Mirage

let main =
  let packages = [ package "duration"; package ~max:"0.1.3" "randomconv" ] in
  main ~packages "Unikernel.Echo_server" (time @-> random @-> job)

let () = register "echo_server" [ main $ default_time $ default_random ]
