open Mirage

let stack = generic_stackv4v6 default_network
let data_key = Key.(value @@ kv_ro ~group:"data" ())
let data = generic_kv_ro ~key:data_key "htdocs"
(* set ~tls to false to get a plain-http server *)
let https_srv = cohttp_server @@ conduit_direct ~tls:true stack

let http_port =
  let doc = Key.Arg.info ~doc:"Listening HTTP port." ["http"] in
  Key.(create "http_port" Arg.(opt int 8080 doc))

let certs_key = Key.(value @@ kv_ro ~group:"certs" ())
(* some default CAs and self-signed certificates are included in
   the tls/ directory, but you can replace them with your own. *)
let certs = generic_kv_ro ~key:certs_key "tls"

let https_port =
  let doc = Key.Arg.info ~doc:"Listening HTTPS port." ["https"] in
  Key.(create "https_port" Arg.(opt int 4433 doc))

let main =
  let packages = [
    package "uri"; package "magic-mime"
  ] in
  let keys = List.map Key.abstract [ http_port; https_port ] in
  foreign
    ~packages ~keys
    "Dispatch.HTTPS" (pclock @-> kv_ro @-> kv_ro @-> http @-> job)

let () =
  register "https" [main $ default_posix_clock $ data $ certs $ https_srv]
