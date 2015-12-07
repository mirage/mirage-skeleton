open Mirage

let main = foreign "Unikernel.Main" (stackv4 @-> job)
let stack console = direct_stackv4_with_default_ipv4 console tap0

let tracing = mprof_trace ~size:1000000 ()

let () =
  register "example" ~tracing [
    main $ stack default_console;
  ]
