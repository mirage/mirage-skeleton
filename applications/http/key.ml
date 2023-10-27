open Cmdliner

let port =
  let doc = Arg.info ~doc:"Port of HTTP service." [ "p"; "port" ] in
  Arg.(value & opt int 8080 doc)
