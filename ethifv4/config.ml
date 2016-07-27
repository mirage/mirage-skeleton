open Mirage

let main =
  let libraries = [
    "tcpip.ethif"; "tcpip.arpv4"; "tcpip.tcp";
    "tcpip.udp"; "tcpip.dhcpv4" ] in
  let packages = ["tcpip"] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (console @-> network @-> clock @-> time @-> job)

let () =
  register "ethifv4" [
    main $ default_console $ tap0 $ default_clock $ default_time
  ]
