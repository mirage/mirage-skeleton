open Mirage

let main =
  main
    ~packages:[package "cohttp-mirage"]
    "Unikernel.Main" (conduit @-> job)

let () =
  register "conduit_server" [ main $ conduit_direct (generic_stackv4 default_network) ]
