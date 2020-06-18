open Mirage

(** Always compile DNS zone file data into the unikernel *)
let data = crunch "./data"

(** Define the shape of the service.  We depend on the `dns`
    package, and it requires a logging console, a read-only
    key/value store and a TCP/IP stack. *)
let dns_handler =
  let packages = [
    package ~min:"1.0.0" "dns";
    package "mirage-dns";
    package ~min:"2.9.0" "ipaddr";
    package "duration"
  ] in
  main
    ~packages
    "Unikernel.Main" (time @-> kv_ro @-> stackv4 @-> job)

let stack = generic_stackv4 default_network

let () =
  register "dns" [dns_handler $ default_time $ data $ stack]
