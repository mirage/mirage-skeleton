(* mirage >= 4.7.0 & < 4.11.0 *)
open Mirage

let client =
  let packages = [ package "cohttp-mirage"; package "duration" ] in
  main ~packages "Unikernel.Client" (http_client @-> job)

let () =
  let dhcp_requests = make_dhcp_requests () in
  let stack, lease = generic_stackv4v6_with_lease ~dhcp_requests default_network in
  let res_dns = resolver_dns ~dhcp:(dhcp_requests, lease) stack in
  let conduit = conduit_direct ~tls:true stack in
  let job = [ client $ cohttp_client res_dns conduit ] in
  register "http-fetch" job
