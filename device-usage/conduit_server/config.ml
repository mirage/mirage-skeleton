open Mirage

let handler =
  let packages = [package ~sublibs:[ "tcp" ] "conduit-mirage"; package "cohttp-mirage"] in
  foreign
    ~packages
    "Unikernel.Main" (stackv4 @-> job)

let () =
  register "conduit_server" [ handler $ (generic_stackv4 default_network) ]
