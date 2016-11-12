open Mirage

let libraries = ["duration"; "randomconv"]
and packages = ["duration"; "randomconv"]

let () =
  try match Sys.getenv "TARGET" with
    | "heads1" ->
      let main = foreign ~libraries ~packages "Unikernels.Heads1" (console @-> job) in
      register "heads1" [ main $ default_console ]
    | "heads2" ->
      let main = foreign ~libraries ~packages "Unikernels.Heads2" (console @-> job) in
      register "heads2" [ main $ default_console ]

    | "timeout1" ->
      let main = foreign ~libraries ~packages "Unikernels.Timeout1" (console @-> random @-> job) in
      register "timeout1" [ main $ default_console $ default_random ]
    | "timeout2" ->
      let main = foreign ~libraries ~packages "Unikernels.Timeout2" (console @-> random @-> job) in
      register "timeout2" [ main $ default_console $ default_random ]

    | "echo_server1" ->
      let main = foreign ~libraries ~packages "Unikernels.Echo_server1" (console @-> random @-> job) in
      register "echo_server1" [ main $ default_console $ default_random ]
  with Not_found -> failwith "Must specify target"
