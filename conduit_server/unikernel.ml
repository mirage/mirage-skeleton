open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (CON:Conduit_mirage.S) = struct

  module H = HTTP.Make(CON)

  let start console ctx =

    let http_callback conn_id req body =
      let path = Uri.path (H.Server.Request.uri req) in
      C.log_s console (sprintf "Got request for %s\n" path) 
      >>= fun () ->
      H.Server.respond_string ~status:`OK ~body:"hello mirage world!\n" ()
    in

    let spec = H.Server.make ~callback:http_callback () in
    CON.serve ~ctx ~mode:(`TCP (`Port 80)) (H.Server.listen spec)
end
