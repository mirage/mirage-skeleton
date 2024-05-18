(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let packages =
  [
    package ~min:"1.0.0" "charrua";
    package "charrua-server";
    package ~min:"3.0.0" ~sublibs:[ "mirage" ] "arp";
    package ~min:"3.0.0" "ethernet";
  ]

let main =
  let extra_deps = [ dep default_time ] in
  main ~extra_deps "Unikernel.Main" ~packages (network @-> mclock @-> job)

let () =
  register "dhcp"
    [ main $ default_network $ default_monotonic_clock ]
