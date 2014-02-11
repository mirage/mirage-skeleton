open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> job)

let () =
  add_to_ocamlfind_libraries [ "tcpip.ethif"; "tcpip.ipv4" ];
  register "ping" [ main $ default_console $ tap0 ]
