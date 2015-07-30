open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> clock @-> job)

let () =
  add_to_opam_packages [ "tcpip" ];
  add_to_ocamlfind_libraries [ "tcpip.arpv4"; "tcpip.ethif"; "tcpip.ipv4" ];
  register "ping" [ main $ default_console $ tap0 $ default_clock ]
