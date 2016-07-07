open Lwt.Infix

let server_src = Logs.Src.create "server" ~doc:"HTTP server"
module Server_log = (val Logs.src_log server_src : Logs.LOG)

module Main (Clock:V1.CLOCK) (FS:V1_LWT.KV_RO) (S:Cohttp_lwt.Server) = struct
  module Logs_reporter = Mirage_logs.Make(Clock)

  let read_fs fs name =
    FS.size fs name >>= function
    | `Error (FS.Unknown_key _) -> Lwt.fail (Failure ("read " ^ name))
    | `Ok size ->
      FS.read fs name 0 (Int64.to_int size) >>= function
      | `Error (FS.Unknown_key _) -> Lwt.fail (Failure ("read " ^ name))
      | `Ok bufs -> Lwt.return (Cstruct.copyv bufs)

  let rec dispatcher fs uri =
    match Uri.path uri with
    | ("" | "/") as path ->
      Server_log.info (fun f -> f "request for '%s'" path);
      dispatcher fs (Uri.with_path uri "index.html")
    | path ->
      Server_log.info (fun f -> f "request for '%s'" path);
      Lwt.catch (fun () ->
          read_fs fs path >>= fun body ->
          let mime_type = Magic_mime.lookup path in
          let headers = Cohttp.Header.init () in
          let headers = Cohttp.Header.add headers "content-type" mime_type in
          S.respond_string ~status:`OK ~body ~headers ()
        ) (fun _exn -> S.respond_not_found ())

  let start _clock fs http =
    Logs.(set_level (Some Info));
    Logs_reporter.(create () |> run) @@ fun () ->

    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Server_log.info (fun f -> f "[%s] serving %s" cid (Uri.to_string uri));
      dispatcher fs uri
    in
    let conn_closed (_, cid) =
      let cid = Cohttp.Connection.to_string cid in
      Server_log.info (fun f -> f "[%s] closing" cid);
    in
    let port = Key_gen.port () in
    Server_log.info (fun f -> f "listening on %d/TCP" port);
    http (`TCP port) (S.make ~conn_closed ~callback ())

end
