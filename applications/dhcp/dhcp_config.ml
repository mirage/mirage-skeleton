
open Dhcp_wire

let ip = Ipaddr.V4.of_string_exn
let net = Ipaddr.V4.Prefix.of_string_exn
let mac = Macaddr.of_string_exn

let hostname =           "charrua-dhcp-server"
let default_lease_time = 60 * 60 * 1 (* 1 hour *)
let max_lease_time =     60 * 60 * 24 (* A day *)
let ip_address =         ip "192.168.1.5"
let network =            net "192.168.1.5/24"
let range =              Some (ip "192.168.1.70", ip "192.168.1.100")
(* List of dhcp options to be advertised *)
let options = [
  (* Routers is a list of default routers *)
  Routers [ip "192.168.1.5"];
  (* Dns_servers is a list of dns servers *)
  Dns_servers [ip "192.168.1.5"; (* ip "192.168.1.6" *)];
  (* Ntp_servers is a list of ntp servers, Time_servers (old protocol) is also available *)
  (* Ntp_servers [ip "192.168.1.5"]; *)
  Domain_name "pampas";
  (*
   * Check dhcp_wire.mli for the other options:
   * https://github.com/haesbaert/charrua-core/blob/master/lib/dhcp_wire.mli
   *)
]

(*
 * Static hosts configuration, list options will be merged with global ones
 * while non-list options will override the global, example: options `Routers',
 * `Dns_servers', `Ntp_servers' will always be merged; `Domain_name',
 * `Time_offset', `Max_datagram; will always override the global (if present).
 *)

let hosts = []

(*
let static_host_1 = {
   Dhcp_server.Config.hostname = "Static host 1";
   options = [
     Routers [ip "192.168.1.4"];
   ];
   hw_addr = mac "7a:bb:c1:aa:50:01";
   fixed_addr = Some (ip "192.168.1.151"); (* Must be outside of range. *)
}

let static_host_2 = {
   Dhcp_server.Config.hostname = "Static host 2";
   options = [];
   hw_addr = mac "7a:bb:c1:aa:50:02";
   fixed_addr = Some (ip "192.168.1.152"); (* Must be outside of range. *)
}

let hosts = [static_host_1;static_host_2]
*)
