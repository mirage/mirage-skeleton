open Mirage

let domain_name =
  let doc = Key.Arg.info ~doc:"The domain-name to resolve." [ "domain-name" ] in
  Key.(create "domain-name" Arg.(required string doc))

let nameservers =
  let doc = Key.Arg.info ~doc:"Nameserver." [ "nameserver" ] in
  Key.(create "nameserver" Arg.(opt_all string doc))

let timeout =
  let doc = Key.Arg.info ~doc:"Timeout of DNS requests." [ "timeout" ] in
  Key.(create "timeout" Arg.(opt (some int64) None doc))

let unikernel = foreign "Unikernel.Make"
  ~keys:[ Key.v domain_name; Key.v nameservers ]
  (console @-> dns_client @-> job)

let stackv4v6 = generic_stackv4v6 default_network

let () = register "resolve" [ unikernel $ default_console $ generic_dns_client ~timeout ~nameservers stackv4v6 ]
