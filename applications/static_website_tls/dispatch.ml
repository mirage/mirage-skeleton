open Lwt.Infix
open Cmdliner

let http_port =
  let doc = Arg.info ~doc:"Listening HTTP port." [ "http" ] in
  Mirage_runtime.register_arg Arg.(value & opt int 80 doc)

let https_port =
  let doc = Arg.info ~doc:"Listening HTTPS port." [ "https" ] in
  Mirage_runtime.register_arg Arg.(value & opt int 443 doc)

module type HTTP = Cohttp_mirage.Server.S
(** Common signature for http and https. *)

(* Logging *)
let https_src = Logs.Src.create "https" ~doc:"HTTPS server"

module Https_log = (val Logs.src_log https_src : Logs.LOG)

let http_src = Logs.Src.create "http" ~doc:"HTTP server"

module Http_log = (val Logs.src_log http_src : Logs.LOG)

module Dispatch (FS : Mirage_kv.RO) (S : HTTP) = struct
  let failf fmt = Fmt.kstr Lwt.fail_with fmt

  (* given a URI, find the appropriate file,
   * and construct a response with its contents. *)
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
            FS.get fs (Mirage_kv.Key.v path) >>= function
            | Error e -> failf "get: %a" FS.pp_error e
            | Ok body -> S.respond_string ~status:`OK ~body ~headers ())
          (fun _exn -> S.respond_not_found ())

  (* Redirect to the same address, but in https. *)
  let redirect port uri =
    let new_uri = Uri.with_scheme uri (Some "https") in
    let new_uri = Uri.with_port new_uri (Some port) in
    Http_log.info (fun f ->
        f "[%s] -> [%s]" (Uri.to_string uri) (Uri.to_string new_uri));
    let headers = Cohttp.Header.init_with "location" (Uri.to_string new_uri) in
    S.respond ~headers ~status:`Moved_permanently ~body:`Empty ()

  let serve dispatch =
    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid =
        begin [@alert "-deprecated"]
          Cohttp.Connection.to_string cid
        end
      in
      Https_log.info (fun f -> f "[%s] serving %s." cid (Uri.to_string uri));
      dispatch uri
    in
    let conn_closed (_, cid) =
      let cid =
        begin [@alert "-deprecated"]
          Cohttp.Connection.to_string cid
        end
      in
      Https_log.info (fun f -> f "[%s] closing" cid)
    in
    S.make ~conn_closed ~callback ()
end

module HTTPS (DATA : Mirage_kv.RO) (KEYS : Mirage_kv.RO) (Http : HTTP) = struct
  module X509 = Tls_mirage.X509 (KEYS)
  module D = Dispatch (DATA) (Http)

  let tls_init kv =
    X509.certificate kv `Default >>= fun cert ->
    let conf =
      Result.get_ok (Tls.Config.server ~certificates:(`Single cert) ())
    in
    Lwt.return conf

  let start data keys http =
    tls_init keys >>= fun cfg ->
    let tls = `TLS (cfg, `TCP (https_port ())) in
    let tcp = `TCP (http_port ()) in
    let https =
      Https_log.info (fun f ->
          f "listening for HTTPS on %d/TCP" (https_port ()));
      http tls @@ D.serve (D.dispatcher data)
    in
    let http =
      Http_log.info (fun f -> f "listening for HTTP on %d/TCP" (http_port ()));
      http tcp @@ D.serve (D.redirect (https_port ()))
    in
    Lwt.join [ https; http ]
end
