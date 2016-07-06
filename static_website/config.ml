open Mirage

let stack = generic_stackv4 default_console tap0
let data = generic_kv_ro "htdocs"
let http_srv = http_server @@ conduit_direct ~tls:false stack

let port =
  let doc = Key.Arg.info ~doc:"Listening port." ["port"] in
  Key.(create "port" Arg.(opt int 8080 doc))

let main =
  let libraries = [ "re.str"; "magic-mime"; "mirage-logs" ] in
  let packages = [ "re"; "magic-mime"; "mirage-logs" ] in
  let keys = [ Key.abstract port ] in
  foreign
    ~libraries ~packages ~keys
    "Dispatch.Main" (clock @-> kv_ro @-> http @-> job)

let () =
  register "www" [main $ default_clock $ data $ http_srv]
