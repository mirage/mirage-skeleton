open Mirage

let main = foreign "Unikernel.Main" (console @-> kv_ro @-> network @-> clock @-> job)

let disk = crunch "files"

let () =
  add_to_ocamlfind_libraries ([ "charrua-core.server";
                                "tcpip"; "tcpip.ethif"; "tcpip.arpv4"; "str"]);
  add_to_opam_packages ["charrua-core"];
  register "dhcp" [
    main $ default_console $ disk $ tap0 $ default_clock
  ]
