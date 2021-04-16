open Mirage

let uri =
  let doc = Key.Arg.info ~doc:"URL to fetch" ["uri"] in
  Key.(create "uri" Arg.(opt string "https://mirage.io" doc))

let client =
  let packages = [ package "cohttp-mirage"; package "duration" ] in
  foreign
    ~keys:[Key.abstract uri]
    ~packages
    "Unikernel.Client" @@ http_client @-> job

let () =
  let stack = generic_stackv4v6 default_network in
  let res_dns = resolver_dns stack in
  let conduit = conduit_direct ~tls:true stack in
  let job =  [ client $ cohttp_client res_dns conduit ] in
  register "http-fetch" job
