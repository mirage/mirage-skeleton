open Mirage

let main =
  main "Unikernel.Main" job

let () =
  register "noop-functor" [main]
