open Mirage

let disk = generic_kv_ro "t"

let main =
  foreign
    ~packages:[package "duration"]
    "Unikernel.Main" (console @-> kv_ro @-> kv_ro @-> job)

let () =
  register "kv_ro" [main $ default_console $ disk $ disk]
