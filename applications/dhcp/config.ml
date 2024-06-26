(* mirage >= 4.4.0 & < 4.7.0 *)
open Mirage

let packages =
  [
    package ~min:"1.0.0" "charrua";
    package "charrua-server";
    package ~min:"3.0.0" ~sublibs:[ "mirage" ] "arp";
    package ~min:"3.0.0" "ethernet";
  ]

let main = main "Unikernel.Main" ~packages (network @-> mclock @-> time @-> job)

let () =
  register "dhcp"
    [ main $ default_network $ default_monotonic_clock $ default_time ]
