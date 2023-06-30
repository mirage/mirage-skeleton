open Mirage

let main = main ~packages:[ package "duration" ] "Unikernel.Hello" (time @-> job)
let () = register "hello-key" [ main $ default_time ]
