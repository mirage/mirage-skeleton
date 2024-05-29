(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  main
    ~packages:[ package ~min:"3.0.0" "ethernet"; package ~min:"7.0.0" "tcpip" ]
    "Unikernel.Main"
    (network @-> ethernet @-> ipv6 @-> job)

let net = default_network
let ethif = ethif net
let ipv6 = create_ipv6 net ethif
let () = register "ping" [ main $ default_network $ ethif $ ipv6 ]
