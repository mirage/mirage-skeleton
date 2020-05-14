open Mirage

let main =
  main
    "Unikernel.Main" (console @-> network @-> ethernet @-> ipv6 @-> job)

let net = default_network
let ethif = etif net
let ipv6 =
  let config = {
    addresses = [];
    netmasks  = [];
    gateways  = [];
  } in
  create_ipv6 ethif config

let () =
  register "ping" [ main $ default_console $ default_network $ ethif $ ipv6 ]
