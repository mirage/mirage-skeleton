(* mirage >= 4.6.0 & < 4.8.0 *)
open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.domain_name" ]
let unikernel = main ~runtime_args "Unikernel.Make" (dns_client @-> job)
let stackv4v6 = generic_stackv4v6 default_network
let happy_eyeballs = generic_happy_eyeballs stackv4v6

let () =
  register "resolve" [ unikernel $ generic_dns_client stackv4v6 happy_eyeballs ]
