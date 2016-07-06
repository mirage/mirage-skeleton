open Mirage

let stack = generic_stackv4 default_console tap0
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
  let libraries = [
    "uri"; "tls"; "tls.mirage"; "mirage-http"; "mirage-logs"; "magic-mime"
  ] in
  let packages = [
    "uri"; "tls"; "mirage-http"; "mirage-logs"; "magic-mime"
  ] in
  let keys = List.map Key.abstract [ http_port; https_port ] in
  foreign
    ~libraries ~packages ~keys
    "Dispatch.HTTPS" (clock @-> kv_ro @-> kv_ro @-> http @-> job)

let () =
  register "https" [main $ default_clock $ data $ certs $ https_srv]
