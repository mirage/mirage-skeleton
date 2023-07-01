open Cmdliner

let nameservers =
  let doc = Arg.info ~doc:"Nameserver." [ "nameserver" ] in
  Arg.(value & opt_all string [] doc)

let timeout =
  let doc = Arg.info ~doc:"Timeout of DNS requests." [ "timeout" ] in
  Arg.(value & opt (some int64) None doc)
