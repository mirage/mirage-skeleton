open Mirage

let main =
  main "Unikernel.Main"
    ~packages:[ package "fmt"; package "dune-build-info" ]
    (job @-> job)

let () = register "app-info" [ main $ noop ]
