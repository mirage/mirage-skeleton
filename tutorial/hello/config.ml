open Mirage

let main = main ~packages:[ package "duration" ] "Unikernel.Hello" (time @-> job)
let () = register "hello" [ main $ default_time ]
