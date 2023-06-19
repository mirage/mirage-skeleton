open Mirage

let main = main "Unikernel.Main" (job @-> job)
let () = register "noop-functor" [ main $ noop ]
