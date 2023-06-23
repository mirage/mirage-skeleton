open Mirage

let packages =
  [
    package "fmt";
    package "mirage-crypto-rng";
    package "mirage-crypto-pk";
    package "mirage-crypto";
  ]

let main = foreign "Unikernel.Main" ~packages (random @-> job)

let () = register "crypto-test" [ main $ default_random ]
