open Mirage

(** Always compile DNS zone file data into the unikernel *)
let data = crunch "./data"

(** Define the shape of the service.  We depend on the `dns`
    package, and it requires a logging console, a read-only
    key/value store and a TCP/IP stack. *)
let dns_handler =
  let libraries = ["dns.mirage"; "mirage-logs"; "duration"] in
  let packages = ["dns"; "mirage-logs"; "duration"] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (clock @-> kv_ro @-> stackv4 @-> job)

let stack = generic_stackv4 tap0

let () =
  register "dns" [dns_handler $ default_clock $ data $ stack]
