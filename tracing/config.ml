open Mirage

let main = foreign "Unikernel.Main" (stackv4 @-> job)
let stack = generic_stackv4 tap0

let tracing = mprof_trace ~size:1000000 ()

let () =
  register "example" ~tracing [
    main $ stack
  ]
