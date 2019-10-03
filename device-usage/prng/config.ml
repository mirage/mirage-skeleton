open Mirage

let main = foreign ~deps:[abstract nocrypto] "Unikernel.Main" (random @-> job)

let () =
  let packages = [
    package "randomconv" ;
    package "mirage-entropy" ;
  ] in
  register ~packages "prng" [main $ default_random]
