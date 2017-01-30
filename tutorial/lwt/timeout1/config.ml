open Mirage

let packages = [package "duration"; package "randomconv"]

let () =
  let main = foreign ~packages "Unikernel.Timeout1" (console @-> random @-> job) in
  register "timeout1" [ main $ default_console $ default_random ]
