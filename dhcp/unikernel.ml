open Lwt.Infix

let server_src = Logs.Src.create "server" ~doc:"HTTP server"
module Server_log = (val Logs.src_log server_src : Logs.LOG)

(* IP Configuration, all you need besides dhcpd.conf. *)
let string_of_stream s =
  let s = List.map Cstruct.to_string s in
  (String.concat "" s)

module Main (Clock : V1.CLOCK) (KV: V1_LWT.KV_RO) (N: V1_LWT.NETWORK) = struct
  module Logs_reporter = Mirage_logs.Make(Clock)
  module E = Ethif.Make(N)
  module A = Arpv4.Make(E)(Clock)(OS.Time)

  let of_interest dest net =
    Macaddr.compare dest (N.mac net) = 0 || not (Macaddr.is_unicast dest)

  let input_dhcp net config leases buf =
    match (Dhcp_wire.pkt_of_buf buf (Cstruct.len buf)) with
    | `Error e ->
      Server_log.warn (fun f -> f "Can't parse packet: %s" e);
      Lwt.return leases
    | `Ok pkt ->
      let open Dhcp_server.Input in
      match (input_pkt config leases pkt (Clock.time ())) with
      | Silence -> Lwt.return leases
      | Update leases ->
        Server_log.info (fun f ->
            let s = Dhcp_wire.pkt_to_string pkt in
            f "Received packet %s - updated lease database" s
          );
        Lwt.return leases
      | Warning w ->
        Server_log.warn (fun f -> f "%s" w);
        Lwt.return leases
      | Error e ->
        Server_log.err (fun f -> f "%s" e);
        Lwt.return leases
      | Reply (reply, leases) ->
        Server_log.info (fun f ->
            let s = Dhcp_wire.pkt_to_string pkt in
            f "Received packet %s" s
          );
        N.write net (Dhcp_wire.buf_of_pkt reply)
        >>= fun () ->
        Server_log.info (fun f ->
            f "Sent reply packet %s" (Dhcp_wire.pkt_to_string reply)
          );
        Lwt.return leases

  let start _clock kv net =
    Logs.(set_level (Some Info));
    Logs_reporter.(create () |> run) @@ fun () ->

    let or_error name fn t =
      fn t >>= function
      | `Error _e -> Lwt.fail (Failure ("Error starting " ^ name))
      | `Ok t     -> Lwt.return t
    in
    let ipaddr = Key_gen.ipaddr () |> Ipaddr.V4.of_string_exn in

    (* Read the config file *)
    or_error "Kv.size" (KV.size kv) "dhcpd.conf"
    >>= fun size ->
    or_error "Kv.read" (KV.read kv "dhcpd.conf" 0) (Int64.to_int size)
    >>= fun v -> Lwt.return (string_of_stream v)
    >>= fun conf ->
    Server_log.info (fun f -> f "Using configuration:\n%s" conf);

    (* Get an ARP stack *)
    or_error "Ethif" E.connect net
    >>= fun e ->
    or_error "Arpv4" A.connect e
    >>= fun a ->
    A.add_ip a ipaddr
    >>= fun () ->

    (* Build a dhcp server *)
    let config = Dhcp_server.Config.parse conf (ipaddr, N.mac net) in
    let leases = ref (Dhcp_server.Lease.make_db ()) in
    let listener = N.listen net (fun buf ->
        match (Wire_structs.parse_ethernet_frame buf) with
        | Some (proto, dst, payload) when of_interest dst net ->
          (match proto with
           | Some Wire_structs.ARP -> A.input a payload
           | Some Wire_structs.IPv4 ->
             if Dhcp_wire.is_dhcp buf (Cstruct.len buf) then
               input_dhcp net config !leases buf >>= fun new_leases ->
               leases := new_leases;
               Lwt.return_unit
             else
               Lwt.return_unit
           | _ -> Lwt.return_unit)
        | _ -> Lwt.return_unit)
    in
    listener
end
