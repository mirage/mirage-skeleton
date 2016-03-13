open V1
open V1_LWT

let (>>=) = Lwt.bind

(** Common signature for http and https. *)
module type HTTP = Cohttp_lwt.Server

(* Logging *)
let server_src = Logs.Src.create "server" ~doc:"HTTPS server"
module Server_log = (val Logs.src_log server_src : Logs.LOG)

module Dispatch (FS: KV_RO) (S: HTTP) = struct

  let read_fs fs name =
    FS.size fs name >>= function
    | `Error (FS.Unknown_key _) ->
      Lwt.fail (Failure ("read " ^ name))
    | `Ok size ->
      FS.read fs name 0 (Int64.to_int size) >>= function
      | `Error (FS.Unknown_key _) -> Lwt.fail (Failure ("read " ^ name))
      | `Ok bufs -> Lwt.return (Cstruct.copyv bufs)

  (* dispatch files *)
  let rec dispatcher fs request uri =
    match Uri.path uri with
    | "" | "/" -> dispatcher fs request (Uri.with_path uri "index.html")
    | path ->
      let header = Cohttp.Header.init_with "Strict-Transport-Security" "max-age=31536000" in
      let mimetype = Magic_mime.lookup path in
      let headers = Cohttp.Header.add header "content-type" mimetype in
      Lwt.catch
        (fun () ->
           read_fs fs path >>= fun body ->
           S.respond_string ~status:`OK ~body ~headers ())
        (fun _exn ->
           S.respond_not_found ())

  (* Redirect to the same address, but in https. *)
  let redirect _request uri =
    let new_uri = Uri.with_scheme uri (Some "https") in
    let new_uri = Uri.with_port new_uri (Some 4433) in
    let headers =
      Cohttp.Header.init_with "location" (Uri.to_string new_uri)
    in
    S.respond ~headers ~status:`Moved_permanently ~body:`Empty ()

  let serve dispatch =
    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Server_log.info (fun f -> f  "[%s] serving %s." cid (Uri.to_string uri));
      dispatch request uri
    in
    let conn_closed (_,cid) =
      let cid = Cohttp.Connection.to_string cid in
      Server_log.info (fun f -> f "[%s] closing" cid);
    in
    S.make ~conn_closed ~callback ()

end

module HTTPS
    (Http : HTTP)
    (DATA : KV_RO) (KEYS: KV_RO)
    (Clock : CLOCK) =
struct

  module X509 = Tls_mirage.X509 (KEYS) (Clock)

  module D  = Dispatch(DATA)(Http)

  module Logs_reporter = Mirage_logs.Make(Clock)


  let tls_init kv =
    X509.certificate kv `Default >>= fun cert ->
    let conf = Tls.Config.server ~certificates:(`Single cert) () in
    Lwt.return conf

  let start http data keys _clock =
    Logs.(set_level (Some Info));
    Logs_reporter.(create () |> run) @@ fun () ->

    tls_init keys >>= fun cfg ->
    let tcp = `TCP 4433 in
    let tls = `TLS (cfg, tcp) in
    Lwt.join [
      http tls @@ D.serve (D.dispatcher data) ;
      http (`TCP 8080) @@ D.serve D.redirect
    ]

end
