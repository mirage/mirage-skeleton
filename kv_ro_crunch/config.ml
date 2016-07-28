open Mirage

let main =
  foreign
    ~libraries:["duration"] ~packages:["duration"]
    "Unikernel.Main" (time @-> console @-> kv_ro @-> kv_ro @-> job)

let disk1 = crunch "t"
let disk2 = crunch "t"

let () =
  register "kv_ro" [main $ default_time $ default_console $ disk1 $ disk2]
