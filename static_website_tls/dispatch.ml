open Lwt
open Printf
open V1_LWT

module Main (C:CONSOLE) (FS:KV_RO) (S:Cohttp_lwt.Server) = struct

  let start c fs http =

    let read_fs name =
      FS.size fs name >>= function
      | `Error (FS.Unknown_key _) -> fail (Failure ("read " ^ name))
      | `Ok size ->
        FS.read fs name 0 (Int64.to_int size) >>= function
        | `Error (FS.Unknown_key _) -> fail (Failure ("read " ^ name))
        | `Ok bufs -> return (Cstruct.copyv bufs)
    in

    (* Split a URI into a list of path segments *)
    let split_path uri =
      let path = Uri.path uri in
      let rec aux = function
        | [] | [""] -> []
        | hd::tl -> hd :: aux tl
      in
      List.filter (fun e -> e <> "")
        (aux (Re_str.(split_delim (regexp_string "/") path)))
    in

    (* dispatch non-file URLs *)
    let rec dispatcher = function
      | [] | [""] -> dispatcher ["index.html"]
      | segments ->
        let path = String.concat "/" segments in
        Lwt.catch (fun () ->
          read_fs path
          >>= fun body ->
          S.respond_string ~status:`OK ~body ()
          ) (fun exn ->
            S.respond_not_found ()
          )
    in

    (* HTTP callback *)
    let callback conn_id request body =
      let uri = Cohttp.Request.uri request in
      dispatcher (split_path uri)
    in
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      C.log c (Printf.sprintf "conn %s closed" cid)
    in
    let tcp = `TCP 443 in
    let tls = `TLS (Tls.Config.server (), tcp) in
    http tls (S.make ~conn_closed ~callback ())

end
