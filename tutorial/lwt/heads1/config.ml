open Mirage

let main =
  main ~packages:[ package "duration" ] "Unikernel.Heads1"
    (time @-> job)

let () = register "heads1" [ main $ default_time ]
