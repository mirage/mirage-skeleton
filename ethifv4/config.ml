open Mirage

let main =
  let packages = [ package ~sublibs:["ethif"; "arpv4"; "ipv4"; "icmpv4"; "tcp"; "udp"] "tcpip"] in
  foreign
    ~packages
    "Unikernel.Main" (console @-> network @-> mclock @-> time @-> random @-> job)

let () =
  register "ethifv4" [
    main $ default_console $ tap0 $ default_monotonic_clock $ default_time $ default_random
  ]
