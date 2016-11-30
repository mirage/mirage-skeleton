open Mirage

let main =
  let packages = [ package ~sublibs:["ethif"; "ipv6"] "tcpip" ] in
  foreign
    ~packages
    "Unikernel.Main" (console @-> network @-> mclock @-> time @-> job)

let () =
  register "ping" [ main $ default_console $ default_network $ default_monotonic_clock $ default_time ]
