open Lwt.Infix
open Cmdliner

let uri =
  let doc = Arg.info ~doc:"URL to fetch" [ "uri" ] in
  Mirage_runtime.register_arg Arg.(value & opt string "https://mirageos.org" doc)

module Client (Client : Cohttp_lwt.S.Client) = struct
  let http_fetch ctx uri =
    Fmt.pr "Fetching %a with Cohttp\n" Uri.pp uri;
    Client.get ~ctx uri >>= fun (response, body) ->
    Cohttp_lwt.Body.to_string body >|= fun body ->
    Logs.app (fun m ->
        m "%a" Sexplib0.Sexp.pp_hum (Cohttp.Response.sexp_of_t response));
    Logs.app (fun m -> m "Received body length: %d\n" (String.length body));
    Logs.app (fun m -> m "Cohttp fetch done\n------------\n")

  let start ctx =
    let uri = Uri.of_string (uri ()) in
    http_fetch ctx uri
end
