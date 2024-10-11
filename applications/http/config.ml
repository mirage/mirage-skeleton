(* mirage >= 4.7.0 & < 4.9.0 *)
open Mirage

type conn = Connect

let conn = typ Connect

let minipaf =
  main "Unikernel.Make"
    ~packages:
      [
        package "digestif";
        package ~min:"0.0.9" "mimic-happy-eyeballs";
        package "hxd" ~sublibs:[ "core"; "string" ];
        package "rresult";
        package "h2" ~min:"0.13.0";
        package "base64" ~sublibs:[ "rfc2045" ];
      ]
    (random @-> kv_ro @-> kv_ro @-> tcpv4v6 @-> conn @-> http_server @-> job)

let conn =
  let connect _ modname = function
    | [ _pclock; _tcpv4v6; ctx ] ->
        code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> assert false
  in
  impl ~connect "Connect.Make" (pclock @-> tcpv4v6 @-> mimic @-> conn)

let stackv4v6 = generic_stackv4v6 default_network
let tcpv4v6 = tcpv4v6_of_stackv4v6 stackv4v6
let he = generic_happy_eyeballs stackv4v6
let dns = generic_dns_client stackv4v6 he
let certificates = crunch "certificates"
let keys = crunch "keys"

let conn =
  let happy_eyeballs = mimic_happy_eyeballs stackv4v6 he dns in
  conn $ default_posix_clock $ tcpv4v6 $ happy_eyeballs

let port = Runtime_arg.create ~pos:__POS__ "Unikernel.port"
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
