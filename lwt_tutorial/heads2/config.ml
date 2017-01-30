open Mirage

let packages = [package "duration"; package "randomconv"]

let () =
  let main = foreign ~packages "Unikernel.Heads2" (console @-> job) in
  register "heads2" [ main $ default_console ]
