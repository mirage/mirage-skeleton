open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> mclock @-> time @-> job)

let () =
  let packages = [
    package ~sublibs:["server"; "wire"] "charrua-core";
    package ~sublibs:["ipv4"; "udp"; "ethif"; "arpv4"] "tcpip"
  ]
  in
  register "dhcp" ~packages [
    main $ default_console $ tap0 $ default_monotonic_clock $ default_time
  ]
