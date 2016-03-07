open Mirage

(** Always compile DNS zone file data into the unikernel *)
let data = crunch "./data"

(** Define the shape of the service.  We depend on the `dns`
    package, and it requires a logging console, a read-only
    key/value store and a TCP/IP stack. *)
let dns_handler =
  let libraries = ["dns.lwt-core"] in
  let packages = ["dns"] in
  foreign
    ~libraries ~packages
    "Unikernel.Main" (console @-> kv_ro @-> stackv4 @-> job)

(** Supply a default console and the data to the DNS handler.
    It still requires a network stack to become a full [job] *)
let dns_handler_with_data =
  dns_handler $     
  default_console $  (* Supply the default logging console *)
  data               (* K/V store builtin to unikernel *)

(** There are two ways of building this: with pure MirageOS
    networking or with standard Unix kernel sockets.
    We define a "direct" key to configure this at build time. *)
let direct_net =
  let doc = Key.Arg.info
    ~doc:"use direct networking if $(i,true) or kernel sockets otherwise"
    [ "direct" ]
  in Key.(create "direct" Arg.(opt ~stage:`Configure bool true doc))

(** [direct_job] defines a job that is the pure OCaml network implementation. *)
let direct_job =
  dns_handler_with_data $
  (direct_stackv4_with_dhcp default_console tap0)
  (* MirageOS TCP/IP stack *)

(* [socket_job] defines a job that uses Unix kernel sockets. *)
let socket_job =
  if_impl Key.is_xen
    noop  (* Do nothing with sockets if we are in Xen *) 
    (dns_handler_with_data $
     socket_stackv4 default_console [Ipaddr.V4.any]) 

(* If the configuration [direct_net] key is true, pick the direct
   networking stack, otherwise select the socket *)
let net =
  if_impl (Key.value direct_net)
    direct_job
    socket_job

let () =
  register "dns" [net]

