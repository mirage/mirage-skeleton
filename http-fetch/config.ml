open Mirage

let client =
  let libraries = [ "mirage-http"; "duration" ] in
  let packages = [ "mirage-http"; "duration" ] in
  foreign
    ~libraries ~packages
    "Unikernel.Client" @@ console @-> resolver @-> conduit @-> job

let () =
  let stack = generic_stackv4 tap0 in
  let res_dns = resolver_dns stack in
  let conduit = conduit_direct stack in
  let job =  [ client $ default_console $ res_dns $ conduit ] in
  register "http-fetch" job
