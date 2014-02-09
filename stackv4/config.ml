open Mirage

let handler = foreign "Unikernel.Main" (console @-> stackv4 @-> job)

let direct console =
  handler $ console $ direct_stackv4_with_default_ipv4 console tap0

let socket console =
  handler $ console $ socket_stackv4 console [Ipaddr.V4.any]

let () =
  add_to_ocamlfind_libraries ["mirage-http"];
  add_to_opam_packages ["mirage-http"];
  register "stackv4" [
    direct default_console;
    socket default_console;
  ]
