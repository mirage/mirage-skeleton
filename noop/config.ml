open Mirage

let main =
  foreign "Unikernel" job

let () =
  register "noop" [main]
