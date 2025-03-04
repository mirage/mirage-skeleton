(* mirage >= 4.9.0 & < 4.10.0 *)
open Mirage

let packages =
  [
    package ~min:"1.6.0" "charrua";
    package "charrua-server";
    package ~min:"3.0.0" ~sublibs:[ "mirage" ] "arp";
    package ~min:"3.0.0" "ethernet";
  ]

let main = main "Unikernel.Main" ~packages (network @-> job)

let () =
  register "dhcp" [ main $ default_network ]
