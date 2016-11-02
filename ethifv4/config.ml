open Mirage

let main =
  let libraries = [
    "tcpip.ethif"; "tcpip.arpv4"; "tcpip.ipv4"; "tcpip.icmpv4"; "tcpip.tcp";
    "tcpip.udp"; ] in
  let packages = ["tcpip"] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (console @-> network @-> mclock @-> time @-> random @-> job)

let () =
  register "ethifv4" [
    main $ default_console $ tap0 $ default_monotonic_clock $ default_time $ stdlib_random
  ]
