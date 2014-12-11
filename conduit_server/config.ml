open Mirage

let handler = foreign "Unikernel.Main" (console @-> conduit @-> job)

let direct =
  let stack = direct_stackv4_with_default_ipv4 default_console tap0 in
  let server = conduit_direct stack in
  handler $ default_console $ server

(* Only add the Unix socket backend if the configuration mode is Unix *)
let socket =
  let c = default_console in
  match get_mode () with
  | `Xen -> []
  | `Unix | `MacOSX -> [ handler $ c $ conduit_direct (socket_stackv4 c [Ipaddr.V4.any]) ]

let () =
  add_to_ocamlfind_libraries ["mirage-http"];
  add_to_opam_packages ["mirage-http"];
  register "conduit_server" (direct :: socket)
