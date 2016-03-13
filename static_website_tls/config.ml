open Mirage

let stack = generic_stackv4 default_console tap0

(* storage configuration *)

let data = generic_kv_ro "htdocs"
let keys = generic_kv_ro "tls"

let server =
  foreign "Dispatch.HTTPS"
    ( http @-> kv_ro @-> kv_ro @-> clock @-> job)

let my_https =
  http_server @@ conduit_direct ~tls:true stack

let () =
  let libraries = ["uri"; "tls"; "tls.mirage"; "mirage-http"; "mirage-logs"; "magic-mime"] in
  let packages = [ "uri"; "tls"; "mirage-http"; "mirage-logs"; "magic-mime"] in
  register "https"
    ~packages ~libraries
  [
    server
    $ my_https
    $ data
    $ keys
    $ default_clock
  ]
