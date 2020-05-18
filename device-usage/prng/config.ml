open Mirage

let main = foreign "Unikernel.Main" (random @-> job)

let () =
  let packages = [
    package "randomconv" ;
    package ~min:"0.7.0" "mirage-crypto-rng" ;
  ] in
  register ~packages "prng" [main $ default_random]
