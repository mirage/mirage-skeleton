open Mirage

let packages = [package "duration"]

let () =
  let main = foreign ~packages "Unikernel.Heads1" (console @-> time @-> job) in
  register "heads1" [ main $ default_console $ default_time ]
