open Mirage

let main =
  let packages = [ "tcpip" ] in
  let libraries = [ "tcpip.ethif"; "tcpip.ipv6" ] in
  foreign
    ~packages ~libraries
    "Unikernel.Main" (console @-> network @-> clock @-> job)

let () =
  register "ping" [ main $ default_console $ tap0 $ default_clock ]
