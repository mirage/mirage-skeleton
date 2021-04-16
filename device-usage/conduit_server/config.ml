open Mirage

let handler =
  let packages = [package "cohttp-mirage"] in
  foreign
    ~packages
    "Unikernel.Main" (conduit @-> job)

let () =
  register "conduit_server" [ handler $ conduit_direct (generic_stackv4v6 default_network) ]
