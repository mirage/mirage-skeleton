open Lwt.Infix

(** Common signature for http and https. *)
module type HTTP = Cohttp_lwt.Server

(* Logging *)
let https_src = Logs.Src.create "https" ~doc:"HTTPS server"
module Https_log = (val Logs.src_log https_src : Logs.LOG)

let http_src = Logs.Src.create "http" ~doc:"HTTP server"
module Http_log = (val Logs.src_log http_src : Logs.LOG)

module Dispatch (FS: V1_LWT.KV_RO) (S: HTTP) = struct

  let read_fs fs name =
    FS.size fs name >>= function
    | `Error (FS.Unknown_key _) ->
      Lwt.fail (Failure ("read " ^ name))
    | `Ok size ->
      FS.read fs name 0 (Int64.to_int size) >>= function
      | `Error (FS.Unknown_key _) -> Lwt.fail (Failure ("read " ^ name))
      | `Ok bufs -> Lwt.return (Cstruct.copyv bufs)

  (* dispatch files *)
  let rec dispatcher fs uri =
    match Uri.path uri with
    | "" | "/" -> dispatcher fs (Uri.with_path uri "index.html")
    | path ->
      let header =
        Cohttp.Header.init_with "Strict-Transport-Security" "max-age=31536000"
      in
      let mimetype = Magic_mime.lookup path in
      let headers = Cohttp.Header.add header "content-type" mimetype in
      Lwt.catch
        (fun () ->
           read_fs fs path >>= fun body ->
           S.respond_string ~status:`OK ~body ~headers ())
        (fun _exn ->
           S.respond_not_found ())

  (* Redirect to the same address, but in https. *)
  let redirect port uri =
    let new_uri = Uri.with_scheme uri (Some "https") in
    let new_uri = Uri.with_port new_uri (Some port) in
    Http_log.info (fun f -> f "[%s] -> [%s]"
                      (Uri.to_string uri) (Uri.to_string new_uri)
                  );
    let headers = Cohttp.Header.init_with "location" (Uri.to_string new_uri) in
    S.respond ~headers ~status:`Moved_permanently ~body:`Empty ()

  let serve dispatch =
    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Https_log.info (fun f -> f "[%s] serving %s." cid (Uri.to_string uri));
      dispatch uri
    in
    let conn_closed (_,cid) =
      let cid = Cohttp.Connection.to_string cid in
      Https_log.info (fun f -> f "[%s] closing" cid);
    in
    S.make ~conn_closed ~callback ()

end

module HTTPS
    (Clock: V1.CLOCK) (DATA: V1_LWT.KV_RO) (KEYS: V1_LWT.KV_RO) (Http: HTTP) =
struct

  module X509 = Tls_mirage.X509(KEYS)(Clock)
  module D = Dispatch(DATA)(Http)
  module Logs_reporter = Mirage_logs.Make(Clock)

  let tls_init kv =
    X509.certificate kv `Default >>= fun cert ->
    let conf = Tls.Config.server ~certificates:(`Single cert) () in
    Lwt.return conf

  let start _clock data keys http =
    Logs.(set_level (Some Info));
    Logs_reporter.(create () |> run) @@ fun () ->

    tls_init keys >>= fun cfg ->
    let https_port = Key_gen.https_port () in
    let tls = `TLS (cfg, `TCP https_port) in
    let http_port = Key_gen.http_port () in
    let tcp = `TCP http_port in
    let https =
      Https_log.info (fun f -> f "listening on %d/TCP" https_port);
      http tls @@ D.serve (D.dispatcher data)
    in
    let http =
      Http_log.info (fun f -> f "listening on %d/TCP" http_port);
      http tcp @@ D.serve (D.redirect https_port)
    in
    Lwt.join [ https; http ]

end
