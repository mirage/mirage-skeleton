open Mirage

let stack = generic_stackv4 tap0
let data = generic_kv_ro "htdocs"
let https_srv = http_server @@ conduit_direct ~tls:true stack

let http_port =
  let doc = Key.Arg.info ~doc:"Listening HTTP port." ["http"] in
  Key.(create "http_port" Arg.(opt int 8080 doc))

let certs = generic_kv_ro "tls"

let https_port =
  let doc = Key.Arg.info ~doc:"Listening HTTPS port." ["https"] in
  Key.(create "https_port" Arg.(opt int 4433 doc))

let main =
  let packages = [
    package "uri"; package "tls"; package "mirage-http"; package "magic-mime"
  ] in
  let keys = List.map Key.abstract [ http_port; https_port ] in
  foreign
    ~packages ~keys
    "Dispatch.HTTPS" (pclock @-> kv_ro @-> kv_ro @-> http @-> job)

let () =
  register "https" [main $ default_posix_clock $ data $ certs $ https_srv]
