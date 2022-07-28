open Mirage

let main = main "Unikernel.Main" (stackv4v6 @-> job)
let stack = generic_stackv4v6 default_network
let tracing = mprof_trace ~size:1000000 ()
let () = register "example" ~tracing [ main $ stack ]
