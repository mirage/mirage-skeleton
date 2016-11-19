open Mirage

let stack = generic_stackv4 tap0
let data = generic_kv_ro "htdocs"
let http_srv = http_server @@ conduit_direct ~tls:false stack

let port =
  let doc = Key.Arg.info ~doc:"Listening port." ["port"] in
  Key.(create "port" Arg.(opt int 8080 doc))

let main =
  let packages = [ package "re"; package "magic-mime" ] in
  let keys = [ Key.abstract port ] in
  foreign
    ~packages ~keys
    "Dispatch.Main" (kv_ro @-> http @-> job)

let () =
  register "www" [main $ data $ http_srv]
