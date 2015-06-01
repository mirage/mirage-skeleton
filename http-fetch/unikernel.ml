open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

let domain = "anil.recoil.org"
let uri = Uri.of_string "http://anil.recoil.org"
let ns = "8.8.8.8"

module Client (C:CONSOLE) (RES:Resolver_lwt.S) (CON:Conduit_mirage.S) = struct

  module HTTP = Cohttp_mirage.Client(CON)

  let http_fetch c resolver ctx =
    C.log_s c (sprintf "Fetching %s with Cohttp:" (Uri.to_string uri)) >>= fun () ->
    let ctx = HTTP.ctx resolver ctx in
    HTTP.get ~ctx uri >>= fun (response, body) ->
    Cohttp_lwt_body.to_string body >>= fun body ->
    C.log_s c (Sexplib.Sexp.to_string_hum (Cohttp.Response.sexp_of_t response)) >>= fun () ->
    C.log_s c (sprintf "Received body length: %d" (String.length body)) >>= fun () ->
    C.log_s c "Cohttp fetch done\n------------\n"

  let manual_http_fetch c resolver ctx =
    Resolver_lwt.resolve_uri ~uri resolver >>= fun endp ->
    CON.endp_to_client ~ctx endp >>= fun client ->
    C.log_s c (Sexplib.Sexp.to_string_hum (Conduit.sexp_of_endp endp)) >>= fun () ->
    lwt (conn, ic, oc) = CON.connect ~ctx client in
    let page = Io_page.(to_cstruct (get 1)) in
    let http_get = "GET / HTTP/1.1\nHost: anil.recoil.org\n\n" in
    Cstruct.blit_from_string http_get 0 page 0 (String.length http_get);
    let buf = Cstruct.sub page 0 (String.length http_get) in
    CON.Flow.write oc buf >>= function
    | `Eof -> C.log_s c "EOF on write"
    | `Error _ -> C.log_s c "ERR on write"
    | `Ok buf -> begin
      CON.Flow.read ic >>= function
      | `Eof -> C.log_s c "EOF"
      | `Error _ -> C.log_s c "ERR"
      | `Ok buf -> C.log_s c (sprintf "OK\n%s\n" (Cstruct.to_string buf))
    end

  let start c res ctx =
    C.log_s c (sprintf "Resolving in 1s using DNS server %s" ns) >>= fun () ->
    OS.Time.sleep 1.0 >>= fun () ->
    http_fetch c res ctx >>= fun () ->
    manual_http_fetch c res ctx

end
