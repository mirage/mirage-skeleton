open Mirage

let port =
  let doc = Key.Arg.info ~doc:"Port of HTTP service." [ "p"; "port" ] in
  Key.(create "ports" Arg.(opt int 8080 doc))

let tls =
  let doc =
    Key.Arg.info ~doc:"Start an HTTP server with a TLS certificate." [ "tls" ]
  in
  Key.(create "tls" Arg.(flag ~stage:`Run doc))

let tls_port =
  let doc = Key.Arg.info ~doc:"Port of HTTPS service." [ "tls-port" ] in
  Key.(create "tls-port" Arg.(opt ~stage:`Run int 4343 doc))

let alpn =
  let doc =
    Key.Arg.info ~doc:"Protocols handled by the HTTP server." [ "alpn" ]
  in
  Key.(create "alpn" Arg.(opt ~stage:`Run (some string) None doc))

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
    ~keys:[ Key.v tls_port; Key.v tls; Key.v alpn ]
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
