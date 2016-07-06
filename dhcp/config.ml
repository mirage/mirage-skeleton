open Mirage

let ipaddr =
  let doc = Key.Arg.info ~doc:"Server IP address." ["ipaddr"] in
  Key.(create "ipaddr" Arg.(opt string "192.168.1.5" doc))

let disk = generic_kv_ro "files"

let main =
  let libraries = [
    "charrua-core.server"; "tcpip"; "tcpip.ethif"; "tcpip.arpv4"; "str"
  ] in
  let packages = ["charrua-core"] in
  let keys = [Key.abstract ipaddr] in
  foreign ~libraries ~packages ~keys
    "Unikernel.Main" (clock @-> kv_ro @-> network @-> job)


let () =
  register "dhcp" [
    main $ default_clock $ disk $ tap0
  ]
