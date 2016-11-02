open Mirage

let handler =
  let libraries = ["mirage-http"] in
  let packages = ["mirage-http"] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (conduit @-> job)

let () =
  register "conduit_server" [ handler $ conduit_direct (generic_stackv4 tap0) ]
