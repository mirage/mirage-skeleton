open Mirage

let port = Runtime_key.create "Key.port"

type conn = Connect

let conn = typ Connect

let minipaf =
  foreign "Unikernel.Make"
    ~packages:
      [
        package "digestif";
        package "mimic-happy-eyeballs";
        package "hxd" ~sublibs:[ "core"; "string" ];
        package "rresult";
        package "base64" ~sublibs:[ "rfc2045" ];
      ]
    (random @-> kv_ro @-> kv_ro @-> tcpv4v6 @-> conn @-> http_server @-> job)

let conn =
  let connect _ modname = function
    | [ _pclock; _tcpv4v6; ctx ] ->
        Fmt.str {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> assert false
  in
  impl ~connect "Connect.Make" (pclock @-> tcpv4v6 @-> mimic @-> conn)

let stackv4v6 = generic_stackv4v6 default_network
let tcpv4v6 = tcpv4v6_of_stackv4v6 stackv4v6
let dns = generic_dns_client stackv4v6
let certificates = crunch "certificates"
let keys = crunch "keys"

let conn =
  let happy_eyeballs =
    mimic_happy_eyeballs stackv4v6 dns (generic_happy_eyeballs stackv4v6 dns)
  in
  conn $ default_posix_clock $ tcpv4v6 $ happy_eyeballs

let http_server = paf_server ~port tcpv4v6

let () =
  register "minipaf"
    [
      minipaf
      $ default_random
      $ certificates
      $ keys
      $ tcpv4v6
      $ conn
      $ http_server;
    ]
