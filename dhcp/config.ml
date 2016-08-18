open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> mclock @-> time @-> job)

let () =
  let libraries = [ "charrua-core.server"; "tcpip.ipv4";
                    "charrua-core.wire"; "tcpip.udp";
                    "tcpip"; "tcpip.ethif"; "tcpip.arpv4"; "str"] in
  let packages = ["charrua-core"; "tcpip"] in
  register "dhcp" ~libraries ~packages [
    main $ default_console $ tap0 $ default_monotonic_clock $ default_time
  ]
