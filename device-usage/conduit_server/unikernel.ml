open Lwt.Infix

module Main (StackV4 : Mirage_stack.V4) = struct
  let src = Logs.Src.create "conduit_server" ~doc:"Conduit HTTP server"
  module Log = (val Logs.src_log src: Logs.LOG)

  module Conduit = Conduit_mirage_tcp.Make(StackV4)

  let start stack =
    let http_callback _conn_id req _body =
      let path = Uri.path (Cohttp.Request.uri req) in
      Log.debug (fun f -> f "Got request for %s\n" path);
      Server_with_conduit.respond_string ~status:`OK ~body:"hello mirage world!\n" ()
    in

    let spec = Server_with_conduit.make ~callback:http_callback () in
    Server_with_conduit.connect
      Conduit.configuration
      Conduit.service >>= fun service ->
    let cfg =
      { Conduit_mirage_tcp.stack
      ; Conduit_mirage_tcp.keepalive= None
      ; Conduit_mirage_tcp.nodelay= false
      ; Conduit_mirage_tcp.port= 80 } in
    service cfg spec
end
