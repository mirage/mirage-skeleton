open Mirage

let main = main ~packages:[ package "duration" ] "Unikernel.Hello" (job @-> job)
let () = register "hello" [ main $ noop ]
