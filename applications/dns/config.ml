(* mirage >= 4.6.0 & < 4.7.0 *)
open Mirage

let timeout = Runtime_arg.create ~pos:__POS__ "Unikernel.timeout"
let nameservers = Runtime_arg.create ~pos:__POS__ "Unikernel.nameservers"
let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.domain_name" ]
let unikernel = main ~runtime_args "Unikernel.Make" (dns_client @-> job)
let stackv4v6 = generic_stackv4v6 default_network
let happy_eyeballs = generic_happy_eyeballs stackv4v6

let () =
  register "resolve"
    [ unikernel $ generic_dns_client ~timeout ~nameservers stackv4v6 happy_eyeballs ]
