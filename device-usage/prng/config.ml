open Mirage

let packages = [
  package "randomconv";
  package ~min:"0.7.0" "mirage-crypto-rng";
  package "fmt";
]

let main = main "Unikernel.Main" ~packages (random @-> job)

let () =
  register "prng" [ main $ default_random ]
