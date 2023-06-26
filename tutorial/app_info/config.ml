open Mirage

let main =
  main "Unikernel.Main"
    ~packages:[ package "fmt" ]
    ~extra_deps:[ dep app_info ]
    (job @-> job)

let () = register "app-info" [ main $ noop ]
