open Lwt.Infix
open Astring

let failf fmt = Fmt.kstrf Lwt.fail_with fmt

let read_fs (type s) (module M:Mirage_kv_lwt.RO with type t=s) t name =
  M.size t name >>= function
  | Error e -> failf "read: %a" M.pp_error e
  | Ok size ->
      M.read t name 0L size >>= function
      | Error e -> failf "read %a" M.pp_error e
      | Ok bufs -> Lwt.return (Cstruct.copyv bufs)

let exists (type s) (module M:Mirage_kv_lwt.RO with type t=s) t name =
  M.mem t name >>= function
  | Ok true -> Lwt.return_true
  | _ -> Lwt.return_false

let respond m t (module S:Cohttp_lwt.Server) path =
  read_fs m t path >>= fun body ->
  let mime_type = Magic_mime.lookup path in
  let headers = Cohttp.Header.init_with "content-type" mime_type in
  S.respond_string ~status:`OK ~body ~headers ()

let dispatcher
  (type s) (module M:Mirage_kv_lwt.RO with type t=s) 
  (module L:Logs.LOG) (module S:Cohttp_lwt.Server) =
  let rec fn fs uri =
    match Uri.path uri with
    | ("" | "/") as path ->
      L.info (fun f -> f "request for '%s'" path);
      fn fs (Uri.with_path uri "index.html")
    | path when String.is_suffix ~affix:"/" path ->
      L.info (fun f -> f "request for '%s'" path);
      fn fs (Uri.with_path uri "index.html")
    | path ->
      L.info (fun f -> f "request for '%s'" path);
      Lwt.catch (fun () -> 
        read_fs (module M) fs path >>= fun body ->
        let mime_type = Magic_mime.lookup path in
        let headers = Cohttp.Header.init_with "content-type" mime_type in
        S.respond_string ~status:`OK ~body ~headers ()
      ) (fun _exn ->
         let with_index = Fmt.strf "%s/index.html" path in
         exists (module M) fs with_index >>= function
         | true -> fn fs (Uri.with_path uri with_index)
         | false ->  S.respond_not_found ()
      )
  in fn

let start (module L:Logs.LOG) 
    (type f) (module M:Mirage_kv_lwt.RO with type t=f)
    (type s) (module S:Cohttp_lwt.Server with type t=s) fs http =

    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      L.info (fun f -> f "[%s] serving %s" cid (Uri.to_string uri));
      dispatcher (module M) (module L) (module S) fs uri
    in
    let conn_closed (_, cid) =
      let cid = Cohttp.Connection.to_string cid in
      L.info (fun f -> f "[%s] closing" cid);
    in
    let port = Key_gen.port () in
    L.info (fun f -> f "listening on %d/TCP" port);
    http (`TCP port) (S.make ~conn_closed ~callback ())
