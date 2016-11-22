open Mirage

let client =
  let packages = [ package "mirage-http"; package "duration" ] in
  foreign
    ~packages
    "Unikernel.Client" @@ time @-> console @-> resolver @-> conduit @-> job

let () =
  let stack = generic_stackv4 tap0 in
  let res_dns = resolver_dns stack in
  let conduit = conduit_direct stack in
  let job =  [ client $ default_time $ default_console $ res_dns $ conduit ] in
  register "http-fetch" job
