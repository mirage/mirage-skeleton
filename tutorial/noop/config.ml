open Mirage

let main = main "Unikernel" job
let () = register "noop" [ main ]
