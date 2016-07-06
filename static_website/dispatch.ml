open Lwt.Infix

let www_src = Logs.Src.create "www" ~doc:"WWW server"
module Www_log = (val Logs.src_log www_src : Logs.LOG)

module Main (Clock:V1.CLOCK) (FS:V1_LWT.KV_RO) (S:Cohttp_lwt.Server) = struct
  module Logs_reporter = Mirage_logs.Make(Clock)

  let read_fs fs name =
    FS.size fs name >>= function
    | `Error (FS.Unknown_key _) -> Lwt.fail (Failure ("read " ^ name))
    | `Ok size ->
      FS.read fs name 0 (Int64.to_int size) >>= function
      | `Error (FS.Unknown_key _) -> Lwt.fail (Failure ("read " ^ name))
      | `Ok bufs -> Lwt.return (Cstruct.copyv bufs)

  let split_path uri =
    let path = Uri.path uri in
    let rec aux = function
      | [] | [""] -> []
      | hd::tl -> hd :: aux tl
    in
    List.filter (fun e -> e <> "")
      (aux (Re_str.(split_delim (regexp_string "/") path)))

  let rec dispatcher fs = function
    | [] | [""] -> dispatcher fs ["index.html"]
    | segments ->
      let path = String.concat "/" segments in
      Www_log.info (fun f -> f "request for '%s'" path);
      Lwt.catch (fun () ->
          read_fs fs path >>= fun body ->
          let mime_type = Magic_mime.lookup path in
          let headers = Cohttp.Header.init () in
          let headers = Cohttp.Header.add headers "content-type" mime_type in
          S.respond_string ~status:`OK ~body ~headers ()
        ) (fun _exn -> S.respond_not_found ())

  let start () fs http =
     Logs.(set_level (Some Info));
     Logs_reporter.(create () |> run) @@ fun () ->

     let callback _conn_id request _body =
       let uri = Cohttp.Request.uri request in
       dispatcher fs (split_path uri)
     in
     let conn_closed (_,conn_id) =
       let cid = Cohttp.Connection.to_string conn_id in
       Www_log.info (fun f ->f "conn %s closed" cid);
     in
     let port = Key_gen.port () in
     Www_log.info (fun f -> f "WWW server listening on %d/TCP" port);
     http (`TCP port) (S.make ~conn_closed ~callback ())

end
