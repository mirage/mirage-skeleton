open Mirage

let main =
  let packages = [ "tcpip" ] in
  let libraries = [ "tcpip.arpv4"; "tcpip.ethif"; "tcpip.ipv4" ] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (console @-> network @-> clock @-> time @-> job)

let () =
  register "ping" [ main $ default_console $ tap0 $ default_clock $ default_time ]
