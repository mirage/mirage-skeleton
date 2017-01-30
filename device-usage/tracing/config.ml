open Mirage

let main = foreign "Unikernel.Main" (stackv4 @-> job)
let stack = generic_stackv4 default_network

let tracing = mprof_trace ~size:1000000 ()

let () =
  register "example" ~tracing [
    main $ stack
  ]
