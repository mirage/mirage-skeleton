open Mirage

let packages = [package "duration"; package "randomconv"]

let () =
  let main = foreign ~packages "Unikernel.Echo_server"
      (console @-> time @-> random @-> job) in
  register "echo_server"
    [ main $ default_console $ default_time $ default_random ]
