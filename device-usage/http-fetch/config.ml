(* mirage >= 4.7.0 & < 4.9.0 *)
open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.uri" ]

let client =
  let packages = [ package "cohttp-mirage"; package "duration" ] in
  main ~runtime_args ~packages "Unikernel.Client" (http_client @-> job)

let () =
  let stack = generic_stackv4v6 default_network in
  let res_dns = resolver_dns stack in
  let conduit = conduit_direct ~tls:true stack in
  let job = [ client $ cohttp_client res_dns conduit ] in
  register "http-fetch" job
