open Mirage

let main =
  foreign "Unikernel.Main" job

let () =
  register "noop" [main]
