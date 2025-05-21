(* mirage >= 4.9.0 & < 4.10.0 *)
open Mirage

let stack = generic_stackv4v6 default_network
let data_key = Key.(value @@ kv_ro ~group:"data" ())
let data = generic_kv_ro ~key:data_key "htdocs"

(* set ~tls to false to get a plain-http server *)
let https_srv = cohttp_server @@ conduit_direct ~tls:true stack
let certs_key = Key.(value @@ kv_ro ~group:"certs" ())

(* some default CAs and self-signed certificates are included in
   the tls/ directory, but you can replace them with your own. *)
let certs = generic_kv_ro ~key:certs_key "tls"

let main =
  let packages = [ package "uri"; package "magic-mime" ] in
  main ~packages "Dispatch.HTTPS" (kv_ro @-> kv_ro @-> http @-> job)

let () = register "https" [ main $ data $ certs $ https_srv ]
