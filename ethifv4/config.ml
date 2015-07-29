open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> clock @-> job)

(* TODO: workaround a bug in the command-line tool by adding Clock
   for Unix (this is pulled in as an implicit dependency in Xen) *)
let unix_libs =
  match get_mode () with
  | `Xen -> []
  | _ -> ["mirage-clock-unix"]

let () =
  add_to_ocamlfind_libraries
    ([ "tcpip.ethif"; "tcpip.arpv4"; "tcpip.tcp"; "tcpip.udp"; "tcpip.dhcpv4" ]
      @ unix_libs);
  register "ethifv4" [
    main $ default_console $ tap0 $ default_clock
  ]
