(* mirage >= 4.10.0 & < 4.11.0 *)
open Mirage

let main = main "Unikernel" job ~local_libs:["hello"]
let () = register "local-library" [ main ]
