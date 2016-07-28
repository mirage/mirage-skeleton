open Mirage

let stack console = generic_stackv4 console tap0

let client =
  let libraries = [ "mirage-http" ] in
  let packages = [ "mirage-http" ] in
  foreign
    ~libraries ~packages
    "Unikernel.Client" @@ time @-> console @-> resolver @-> conduit @-> job

let () =
  let sv4 = stack default_console in
  let res_dns = resolver_dns sv4 in
  let conduit = conduit_direct sv4 in
  let job =  [ client $ default_time $ default_console $ res_dns $ conduit ] in
  register "http-fetch" job
