open Mirage

let disk = generic_kv_ro "t"

let main =
  foreign
    "Unikernel.Main" (kv_ro @-> job)

let () =
  register "kv_ro" [main $ disk]
