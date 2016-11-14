open Lwt.Infix
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

let domain = "anil.recoil.org"
let uri = Uri.of_string "http://anil.recoil.org"
let ns = "8.8.8.8"

module Client (T: TIME) (C: CONSOLE) (RES: Resolver_lwt.S) (CON: Conduit_mirage.S) = struct

  let http_fetch c resolver ctx =
    C.log c (sprintf "Fetching %s with Cohttp:" (Uri.to_string uri)) >>= fun () ->
    let ctx = Cohttp_mirage.Client.ctx resolver ctx in
    Cohttp_mirage.Client.get ~ctx uri >>= fun (response, body) ->
    Cohttp_lwt_body.to_string body >>= fun body ->
    C.log c (Sexplib.Sexp.to_string_hum (Cohttp.Response.sexp_of_t response)) >>= fun () ->
    C.log c (sprintf "Received body length: %d" (String.length body)) >>= fun () ->
    C.log c "Cohttp fetch done\n------------\n"

  let manual_http_fetch c resolver ctx =
    Resolver_lwt.resolve_uri ~uri resolver >>= fun endp ->
    Conduit_mirage.client endp >>= fun client ->
    C.log c (Sexplib.Sexp.to_string_hum (Conduit.sexp_of_endp endp)) >>= fun () ->
    CON.connect ctx client >>= fun flow ->
    let page = Io_page.(to_cstruct (get 1)) in
    let http_get = "GET / HTTP/1.1\nHost: anil.recoil.org\n\n" in
    Cstruct.blit_from_string http_get 0 page 0 (String.length http_get);
    let buf = Cstruct.sub page 0 (String.length http_get) in
    Conduit_mirage.Flow.write flow buf >>= function
    | `Eof     -> C.log c "EOF on write"
    | `Error _ -> C.log c "ERR on write"
    | `Ok _buf ->
      Conduit_mirage.Flow.read flow >>= function
      | `Eof -> C.log c "EOF"
      | `Error _ -> C.log c "ERR"
      | `Ok buf -> C.log c (sprintf "OK\n%s\n" (Cstruct.to_string buf))

  let start _time c res (ctx:CON.t) =
    C.log c (sprintf "Resolving in 1s using DNS server %s" ns) >>= fun () ->
    OS.Time.sleep_ns (Duration.of_sec 1) >>= fun () ->
    http_fetch c res ctx >>= fun () ->
    manual_http_fetch c res ctx

end
