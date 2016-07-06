open Mirage

let handler =
  let libraries = ["mirage-http"] in
  let packages = ["mirage-http"] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (console @-> conduit @-> job)

let direct =
  let stack = direct_stackv4_with_default_ipv4 tap0 in
  let server = conduit_direct stack in
  handler $ default_console $ server

(* Only add the Unix socket backend if the configuration mode is Unix *)
let socket =
  let c = default_console in
  if_impl Key.is_xen
    noop
    (handler $ c $ conduit_direct (socket_stackv4 c [Ipaddr.V4.any]))

let () =
  register "conduit_server" [direct ; socket ]
