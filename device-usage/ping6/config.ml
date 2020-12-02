open Mirage

let main =
  foreign
    "Unikernel.Main" (console @-> network @-> ethernet @-> ipv6 @-> job)
let net = default_network
let ethif = etif net
let ipv6 = create_ipv6 net ethif

let () =
  register "ping" [ main $ default_console $ default_network $ ethif $ ipv6 ]
