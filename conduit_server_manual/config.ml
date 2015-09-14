open Mirage

let handler =
  let libraries = ["mirage-http"; "vchan"] in
  let packages = ["mirage-http"; "vchan"] in
  foreign
    ~libraries ~packages
    ~deps:[abstract nocrypto]
    "Unikernel.Main" (console @-> stackv4 @-> job)

let direct =
  let stack = direct_stackv4_with_default_ipv4 default_console tap0 in
  handler $ default_console $ stack

(* Only add the Unix socket backend if the configuration mode is Unix *)
let socket =
  let c = default_console in
  if_impl Key.is_xen
    noop
    (handler $ c $ socket_stackv4 c [Ipaddr.V4.any])

let () =
  register "conduit_server" [direct ; socket]
