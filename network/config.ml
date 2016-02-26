open Mirage

let main = foreign "Unikernel.Main" (console @-> stackv4 @-> job)

let stack = generic_stackv4 default_console tap0

let () =
  register "network" [
    main $ default_console $ stack
  ]
