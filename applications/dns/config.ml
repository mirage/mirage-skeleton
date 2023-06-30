open Mirage

let nameservers =
  let doc = Key.Arg.info ~doc:"Nameserver." [ "nameserver" ] in
  Key.(create "nameserver" Arg.(opt_all ~stage:`Run string doc))

let timeout =
  let doc = Key.Arg.info ~doc:"Timeout of DNS requests." [ "timeout" ] in
  Key.(create "timeout" Arg.(opt ~stage:`Run (some int64) None doc))

let unikernel = foreign "Unikernel.Make" (dns_client @-> job)
let stackv4v6 = generic_stackv4v6 default_network

let () =
  register "resolve"
    [ unikernel $ generic_dns_client ~timeout ~nameservers stackv4v6 ]
