(* mirage >= 4.4.0 & < 4.7.0 *)
open Mirage

let packages =
  [
    package "fmt";
    package ~min:"0.2.0" "ohex";
    package ~min:"1.2.0" "digestif";
    package ~min:"1.0.0" "mirage-crypto-rng";
    package ~min:"1.0.0" "mirage-crypto-pk";
    package ~min:"1.0.0" "mirage-crypto";
    package ~min:"0.2.0" "randomconv";
  ]

let main = main "Unikernel.Main" ~packages (random @-> job)
let () = register "crypto-test" [ main $ default_random ]
