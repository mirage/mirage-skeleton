open Mirage

let main = foreign "Unikernel.Main" (random @-> job)

let () =
  let packages = [
    package "randomconv" ;
    package "mirage-crypto-entropy" ;
  ] in
  register ~packages "prng" [main $ default_random]
