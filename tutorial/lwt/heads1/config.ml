open Mirage

let packages = [package "duration"; package "randomconv"]

let () =
  let main = foreign ~packages "Unikernel.Heads1" (console @-> job) in
  register "heads1" [ main $ default_console ]
