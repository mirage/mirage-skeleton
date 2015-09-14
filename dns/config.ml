open Mirage

let data = crunch "./data"

let handler =
  let libraries = ["dns.lwt-core"] in
  let packages = ["dns"] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (console @-> kv_ro @-> stackv4 @-> job)

let direct =
  let stack = direct_stackv4_with_default_ipv4 default_console tap0 in
  handler $ default_console $ data $ stack

(* Only add the Unix socket backend if the configuration mode is Unix *)
let socket =
  let c = default_console in
  if_impl Key.is_xen
    noop
    (handler $ c $ data $ socket_stackv4 c [Ipaddr.V4.any])

let () =
  register "dns" [direct ; socket]
