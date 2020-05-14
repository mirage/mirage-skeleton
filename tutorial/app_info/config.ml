open Mirage

let main =
  main "Unikernel.Main"
    ~packages:[package "fmt"]
    ~extra_deps:[dep app_info]
    (console @-> job)

let () =
  register "app-info" [main $ default_console]
