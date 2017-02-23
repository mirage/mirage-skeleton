open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> mclock @-> time @-> job)

let () =
  let packages = [
    package ~sublibs:["server"; "wire"] "charrua-core";
    package ~sublibs:["ethif"; "arpv4"] "tcpip"
  ]
  in
  register "dhcp" ~packages [
    main $ default_console $ default_network $ default_monotonic_clock $ default_time
  ]
