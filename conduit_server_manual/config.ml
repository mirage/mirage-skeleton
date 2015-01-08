open Mirage

let handler = foreign "Unikernel.Main" (console @-> stackv4 @-> job)

let direct =
  let stack = direct_stackv4_with_default_ipv4 default_console tap0 in
  handler $ default_console $ stack

(* Only add the Unix socket backend if the configuration mode is Unix *)
let socket =
  let c = default_console in
  match get_mode () with
  | `Xen -> []
  | _    -> [ handler $ c $ socket_stackv4 c [Ipaddr.V4.any] ]

let () =
  add_to_ocamlfind_libraries ["mirage-http"; "vchan"];
  add_to_opam_packages ["mirage-http"; "vchan"];
  register "conduit_server" (direct :: socket)
