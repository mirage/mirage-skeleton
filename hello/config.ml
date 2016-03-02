open Mirage

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." ["hello"] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let main =
  foreign
    ~keys:[Key.abstract key]
    "Unikernel.Main" (console @-> job)

let () =
  register "console" [main $ default_console]
