open Mirage

let uri =
  let doc = Key.Arg.info ~doc:"URL to fetch" ["uri"] in
  Key.(create "uri" Arg.(opt string "http://mirage.io" doc))

let client =
  let packages = [ package "cohttp-mirage"; package "duration" ] in
  foreign
    ~keys:[Key.abstract uri]
    ~packages
    "Unikernel.Client" @@ time @-> console @-> resolver @-> conduit @-> job

let () =
  let stack = generic_stackv4 default_network in
  let res_dns = resolver_dns stack in
  let conduit = conduit_direct stack in
  let job =  [ client $ default_time $ default_console $ res_dns $ conduit ] in
  register "http-fetch" job
