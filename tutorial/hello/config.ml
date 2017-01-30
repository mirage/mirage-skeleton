open Mirage

let main =
  foreign
    ~packages:[package "duration"]
    "Unikernel.Hello" (pclock @-> job)

let () =
  register "hello" [main $ default_posix_clock]
