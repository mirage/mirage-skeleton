(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  main "Unikernel.Hello" (time @-> job) ~packages:[ package "duration" ]

let () = register "hello" [ main $ default_time ]
