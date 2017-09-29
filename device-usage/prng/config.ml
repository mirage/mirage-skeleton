open Mirage

let main = foreign ~deps:[abstract nocrypto] "Unikernel.Main" (random @-> job)

let () =
  let packages = [
    package "randomconv" ;
    package "mirage-entropy" ;
    (* access to entropy sources is only via Nocrypto_entropy_mirage.sources,
       which is only compiled when nocrypto uses xen or freestanding flags *)
    package ~ocamlfind:[] "mirage-solo5" ;
    package ~sublibs:["mirage"] "nocrypto"
  ] in
  register ~packages "prng" [main $ default_random]
