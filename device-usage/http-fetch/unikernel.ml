open Lwt.Infix
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

module Client (Client: Cohttp_lwt.S.Client) = struct

  let http_fetch ctx uri =
    Fmt.pr "Fetching %a with Cohttp\n" Uri.pp uri;
    Client.get ~ctx uri >>= fun (response, body) ->
    Cohttp_lwt.Body.to_string body >|= fun body ->
    Fmt.pr "%a\n" Sexplib.Sexp.pp_hum (Cohttp.Response.sexp_of_t response);
    Fmt.pr "Received body length: %d\n" (String.length body);
    Fmt.pr "Cohttp fetch done\n------------\n"

  let start ctx =
    let uri = Uri.of_string (Key_gen.uri ()) in
    http_fetch ctx uri
end
