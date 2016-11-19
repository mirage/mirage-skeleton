open Mirage

(** Always compile DNS zone file data into the unikernel *)
let data = crunch "./data"

(** Define the shape of the service.  We depend on the `dns`
    package, and it requires a logging console, a read-only
    key/value store and a TCP/IP stack. *)
let dns_handler =
  let packages = [package ~sublibs:["mirage"] "dns"; package "duration"] in
  foreign
    ~packages
    "Unikernel.Main" (kv_ro @-> stackv4 @-> job)

let stack = generic_stackv4 tap0

let () =
  register "dns" [dns_handler $ data $ stack]
