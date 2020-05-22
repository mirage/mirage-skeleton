open Mirage

let uri =
  let doc = Key.Arg.info ~doc:"URL to fetch" ["uri"] in
  Key.(create "uri" Arg.(opt string "http://mirage.io" doc))

let client =
  let packages = [ package "cohttp-mirage"
                 ; package "duration"
                 ; package "conduit-mirage" ~sublibs:[ "tcp"; "tls"; "dns"; ]
                 ; package "conduit" ] in
  foreign
    ~keys:[Key.abstract uri; Key.(abstract (resolver ())); Key.(abstract (resolver_port ())) ]
    ~packages
    "Unikernel.Client" @@ random @-> time @-> mclock @-> stackv4 @-> console @-> job

let () =
  let stack = generic_stackv4 default_network in
  let job =  [ client $ default_random $ default_time $ default_monotonic_clock $ stack $ default_console ] in
  register "http-fetch" job
