open Mirage

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." ["hello"] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let main =
  foreign
    ~keys:[Key.abstract key]
    ~packages:[package "duration"]
    "Unikernel.Hello" (time @-> job)

let () =
  register "hello" [main $ default_time]
