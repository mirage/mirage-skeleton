open Lwt.Infix
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")
let localhost  = Domain_name.(host_exn (of_string_exn "localhost"))
let ( <.> ) f g = fun x -> f (g x)

module Client
    (R : Mirage_random.S)
    (T : Mirage_time.S)
    (M : Mirage_clock.MCLOCK)
    (S : Mirage_stack.V4)
    (C : Mirage_console.S) = struct
  module Resolver = Conduit_mirage_dns.Make(R)(T)(M)(S)
  module TCP = Conduit_mirage_tcp.Make(S)

  let tls_endpoint, tls_protocol = Conduit_mirage_tls.protocol_with_tls
                                     ~key:TCP.endpoint TCP.protocol

  let https_resolver stack dns ?(authenticator= (fun ~host:_ _ -> Ok None)) ?nameserver resolvers =
    let resolver domain_name =
      Resolver.resolv dns ?nameserver ~port:443 domain_name >>= function
      | Some (ip, port) ->
        let edn = { Conduit_mirage_tcp.stack; keepalive= None; nodelay= false; ip; port; } in
        Lwt.return_some (edn, Tls.Config.client ~authenticator ())
      | None -> Lwt.return_none in
    Conduit_mirage.register_resolver ~key:tls_endpoint ~priority:10 resolver resolvers

  let http_resolver stack dns ?nameserver resolvers =
    let resolver domain_name =
      Resolver.resolv dns ?nameserver ~port:80 domain_name >>= function
      | Some (ip, port) ->
        let edn = { Conduit_mirage_tcp.stack; keepalive= None; nodelay= false; ip; port; } in
        Lwt.return_some edn
      | None -> Lwt.return_none in
    Conduit_mirage.register_resolver ~key:TCP.endpoint ~priority:20 resolver resolvers

  let resolve_uri resolvers uri =
    let host = Option.value ~default:localhost
        (Option.map Domain_name.(host_exn <.> of_string_exn) (Uri.host uri)) in
    Conduit_mirage.flow resolvers host >>= function
    | Ok flow -> Lwt.return flow
    | Error err -> Format.kasprintf (fun err -> Lwt.fail (Failure err)) "<%a> unreachable: %a"
                     Domain_name.pp host Conduit_mirage.pp_error err

  let http_fetch c resolvers uri =
    C.log c (sprintf "Fetching %s with Cohttp:" (Uri.to_string uri)) >>= fun () ->
    Cohttp_mirage.Client.get ~resolvers uri >>= fun (response, body) ->
    Cohttp_lwt.Body.to_string body >>= fun body ->
    C.log c (Sexplib.Sexp.to_string_hum (Cohttp.Response.sexp_of_t response)) >>= fun () ->
    C.log c (sprintf "Received body length: %d" (String.length body)) >>= fun () ->
    C.log c "Cohttp fetch done\n------------\n"

  let manual_http_fetch c resolvers uri =
    resolve_uri resolvers uri >>= fun flow ->
    let page = Io_page.(to_cstruct (get 1)) in
    let http_get = "GET / HTTP/1.1\nHost: anil.recoil.org\n\n" in
    Cstruct.blit_from_string http_get 0 page 0 (String.length http_get);
    let buf = Cstruct.sub page 0 (String.length http_get) in
    Conduit_mirage.send flow buf >>= function
    | Error _ -> C.log c "ERR on write"
    | Ok _send ->
      let rec go cs =
        let page = Io_page.(to_cstruct (get 1)) in
        Conduit_mirage.recv flow page >>= function
      | Error _ -> C.log c "ERR on read" >>= fun () -> assert false
      | Ok `End_of_input -> Lwt.return (List.rev cs)
      | Ok (`Input len) ->
        let cs = Cstruct.sub page 0 len :: cs in
        go cs in
      go [] >|= Cstruct.concat >>= fun v ->
      C.log c (sprintf "OK\n%s\n" (Cstruct.to_string v))

  let start _random _time _mclock stackv4 c =
    let ns, ns_port = Key_gen.resolver (), Key_gen.resolver_port () in
    let uri = Uri.of_string (Key_gen.uri ()) in
    let dns = Resolver.create stackv4 in

    let resolvers =
      Conduit.empty
      |> http_resolver stackv4 dns ~nameserver:(`TCP, (ns, ns_port))
      |> https_resolver stackv4 dns ~nameserver:(`TCP, (ns, ns_port)) in

    C.log c (sprintf "Resolving using DNS server %s" (Ipaddr.V4.to_string ns)) >>= fun () ->
    http_fetch c resolvers uri >>= fun () ->
    manual_http_fetch c resolvers uri
end
