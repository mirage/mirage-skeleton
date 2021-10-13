open Mirage

let disk = generic_kv_ro "t"
let main = main "Unikernel.Main" (kv_ro @-> job)
let () = register "kv_ro" [ main $ disk ]
