open Mirage

let main =
  main
    ~packages:[ package "duration"; package ~max:"0.1.3" "randomconv" ]
    "Unikernel.Timeout1"
    (time @-> random @-> job)

let () = register "timeout1" [ main $ default_time $ default_random ]
