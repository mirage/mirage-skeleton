(* mirage >= 4.8.0 & < 4.11.0 *)
open Mirage

let unikernel = main "Unikernel.Make" (dns_client @-> job)
let dhcp_requests = make_dhcp_requests ()
let stackv4v6, lease = generic_stackv4v6_with_lease ~dhcp_requests default_network
let happy_eyeballs = generic_happy_eyeballs stackv4v6

let () =
  register "resolve" [ unikernel $ generic_dns_client ~dhcp:(dhcp_requests, lease) stackv4v6 happy_eyeballs ]
