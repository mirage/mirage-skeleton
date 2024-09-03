(* mirage >= 4.4.0 & < 4.7.0 *)
open Mirage

let packages =
  [
    package "fmt";
    package "ohex";
    package "digestif";
    package "mirage-crypto-rng";
    package "mirage-crypto-pk";
    package "mirage-crypto";
  ]

let main = main "Unikernel.Main" ~packages (random @-> job)
let () = register "crypto-test" [ main $ default_random ]
