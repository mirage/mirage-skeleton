open Printf
open Lwt

module CL = Cohttp_lwt_mirage
module C = Cohttp

let string_of_stream s =
  Lwt_stream.to_list s >|= Cstruct.copyv

(* handle exceptions with a 500 *)
let exn_handler exn =
  let body = Printexc.to_string exn in
  eprintf "HTTP: ERROR: %s\n" body;
  return ()

let rec remove_empty_tail = function
  | [] | [""] -> []
  | hd::tl -> hd :: remove_empty_tail tl

(* main callback function *)
let t conn_id ?body req =
  let path = Uri.path (CL.Request.uri req) in
  let path_elem =
    remove_empty_tail (Re_str.(split_delim (regexp_string "/") path))
  in
  lwt static =
    eprintf "finding the static kv_ro block device\n";
    OS.Devices.find_kv_ro "static" >>=
    function
    | None   -> Printf.printf "fatal error, static kv_ro not found\n%!"; exit 1
    | Some x -> return x in

  (* determine if it is static or dynamic content *)
  match_lwt static#read path with
  | Some body ->
     lwt body = string_of_stream body in
     CL.Server.respond_string ~status:`OK ~body ()
  | None -> if path = "/" then
      (* Return the index page *)
      static#read "index.html"
      >>= function
      | Some b ->
        lwt body = string_of_stream b in CL.Server.respond_string ~status:`OK ~body ()
      | None -> assert false
    else
      CL.Server.respond_not_found ~uri:(CL.Request.uri req) ()
