open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> job)

let () =
  add_to_ocamlfind_libraries 
    [ "mirage-clock-unix";
      "tcpip.ethif"; "tcpip.tcpv4"; "tcpip.udpv4"; "tcpip.dhcpv4"
    ];
  register "ethifv4" [
    main $ default_console $ tap0
  ]
