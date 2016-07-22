open Mirage

let main =
  foreign "Unikernel.Main"
    ~packages:["fmt"] ~libraries:["fmt"]
    ~deps:[abstract app_info]
    (console @-> job)

let () =
  register "console" [main $ default_console]
