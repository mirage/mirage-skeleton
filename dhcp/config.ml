open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> clock @-> job)

let disk = crunch "files"

let () =
  add_to_ocamlfind_libraries ([ "charrua-core.server"; "tcpip.ipv4";
                                "charrua-core.wire"; "tcpip.udp";
                                "tcpip"; "tcpip.ethif"; "tcpip.arpv4"; "str"]);
  add_to_opam_packages ["charrua-core"; "tcpip"];
  register "dhcp" [
    main $ default_console $ tap0 $ default_clock
  ]
