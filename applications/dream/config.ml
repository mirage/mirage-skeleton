open Mirage

let packages = [ package "dream-mirage" ]

let http =
  main "Unikernel.Make" ~packages (pclock @-> time @-> stackv4v6 @-> job)

let default_stack = generic_stackv4v6 default_network

let () =
  register "dream" [ http $ default_posix_clock $ default_time $ default_stack ]
