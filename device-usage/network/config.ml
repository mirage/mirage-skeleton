(* mirage >= 4.5.0 & < 4.11.0 *)
open Mirage

let main = main "Unikernel.Main" (stackv4v6 @-> job)
let stack = generic_stackv4v6 default_network
let () = register "network" [ main $ stack ]
