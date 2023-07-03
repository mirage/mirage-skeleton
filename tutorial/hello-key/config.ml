open Mirage

let hello =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt ~stage:`Run string "Hello World!" doc))

let main =
  main
    ~keys:[ key hello ]
    ~packages:[ package "duration" ]
    "Unikernel.Hello" (time @-> job)

let () = register "hello-key" [ main $ default_time ]
