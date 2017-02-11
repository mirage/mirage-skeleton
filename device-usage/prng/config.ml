open Mirage

let main = foreign ~deps:[abstract nocrypto] "Unikernel.Main" (random @-> job)

let () =
  let packages = [
    package "randomconv" ;
    package "mirage-entropy" ;
    package ~sublibs:["mirage"] "nocrypto"
  ] in
  register ~packages "prng" [main $ default_random]
