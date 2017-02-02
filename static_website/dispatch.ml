let server_src = Logs.Src.create "server" ~doc:"HTTP server"
module Server_log = (val Logs.src_log server_src : Logs.LOG)

module Main (FS:Mirage_types_lwt.KV_RO) (S:Cohttp_lwt.Server) = struct

  let start fs http =
    Shim.start (module Server_log) (module FS) (module S) fs http

end
