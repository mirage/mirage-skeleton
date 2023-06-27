open Mirage

let main = main "Unikernel.Hello" (time @-> job) ~packages:[ package "duration" ]
let () = register "hello" [ main $ default_time ]
