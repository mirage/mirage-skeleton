(* mirage >= 4.8.0 & < 4.9.0 *)
open Mirage

let unikernel = main "Unikernel.Make" (dns_client @-> job)
let stackv4v6 = generic_stackv4v6 default_network
let happy_eyeballs = generic_happy_eyeballs stackv4v6

let () =
  register "resolve" [ unikernel $ generic_dns_client stackv4v6 happy_eyeballs ]
