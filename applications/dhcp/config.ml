open Mirage

let main =
  main "Unikernel.Main" (network @-> mclock @-> time @-> job)

let () =
  let packages =
    [
      package ~min:"1.0.0" "charrua";
      package "charrua-server";
      package ~min:"3.0.0" ~sublibs:[ "mirage" ] "arp";
      package ~min:"3.0.0" "ethernet";
    ]
  in
  register "dhcp" ~packages
    [
      main
      $ default_network
      $ default_monotonic_clock
      $ default_time;
    ]
