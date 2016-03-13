open Mirage

let stack = generic_stackv4 default_console tap0

(* storage configuration *)

let data = generic_kv_ro "htdocs"
let keys = generic_kv_ro "tls"

(* main app *)

let https =
  let libraries = ["uri"; "tls"; "tls.mirage"; "mirage-http"; "mirage-logs"; "magic-mime"] in
  let packages = [ "uri"; "tls"; "mirage-http"; "mirage-logs"; "magic-mime"] in
  foreign "Dispatch.HTTPS"
    ~packages ~libraries ~deps:[abstract nocrypto]
    (console @-> stackv4 @-> kv_ro @-> kv_ro @-> clock @-> job)

let () =
  register "https" [
    https
      $ default_console
      $ stack
      $ data
      $ keys
      $ default_clock
  ]
