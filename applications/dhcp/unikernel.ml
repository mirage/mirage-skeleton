open Lwt.Infix

module Main
    (N : Mirage_net.S)
    (MClock : Mirage_clock.MCLOCK)
    (Time : Mirage_time.S) =
struct
  module E = Ethernet.Make (N)
  module A = Arp.Make (E) (Time)
  module DC = Dhcp_config

  let of_interest dest net =
    Macaddr.compare dest (N.mac net) = 0 || not (Macaddr.is_unicast dest)

  let input_dhcp clock net config leases buf =
    match Dhcp_wire.pkt_of_buf buf (Cstruct.length buf) with
    | Error e ->
        Logs.err (fun m -> m "Can't parse packet: %s" e);
        Lwt.return leases
    | Ok pkt -> (
        let open Dhcp_server.Input in
        let now = MClock.elapsed_ns clock |> Duration.to_sec |> Int32.of_int in
        match input_pkt config leases pkt now with
        | Silence -> Lwt.return leases
        | Update leases ->
            Logs.info (fun m ->
                m "Received packet %s - updated lease database"
                  (Dhcp_wire.pkt_to_string pkt));
            Lwt.return leases
        | Warning w ->
            Logs.warn (fun m -> m "%s" w);
            Lwt.return leases
        | Dhcp_server.Input.Error e ->
            Logs.err (fun m -> m "%s" e);
            Lwt.return leases
        | Reply (reply, leases) ->
            Logs.info (fun m ->
                m "Received packet %s" (Dhcp_wire.pkt_to_string pkt));
            N.write net
              ~size:(N.mtu net + Ethernet.Packet.sizeof_ethernet)
              (Dhcp_wire.pkt_into_buf reply)
            >>= fun _ ->
            Logs.info (fun m ->
                m "Sent reply packet %s" (Dhcp_wire.pkt_to_string reply));
            Lwt.return leases)

  let start net clock _time =
    (* Get an ARP stack *)
    E.connect net >>= fun e ->
    A.connect e >>= fun a ->
    A.add_ip a DC.ip_address >>= fun () ->
    (* Build a dhcp server *)
    let config =
      Dhcp_server.Config.make ~hostname:DC.hostname
        ~default_lease_time:DC.default_lease_time
        ~max_lease_time:DC.max_lease_time ~hosts:DC.hosts
        ~addr_tuple:(DC.ip_address, N.mac net)
        ~network:DC.network ~range:DC.range ~options:DC.options ()
    in
    let leases = ref (Dhcp_server.Lease.make_db ()) in
    let listener =
      N.listen net ~header_size:Ethernet.Packet.sizeof_ethernet (fun buf ->
          match Ethernet.Packet.of_cstruct buf with
          | Result.Error s ->
              Logs.err (fun m -> m "Can't parse packet: %s" s);
              Lwt.return_unit
          | Result.Ok (ethif_header, ethif_payload) ->
              if
                of_interest ethif_header.Ethernet.Packet.destination net
                && Dhcp_wire.is_dhcp buf (Cstruct.length buf)
              then (
                input_dhcp clock net config !leases buf >>= fun new_leases ->
                leases := new_leases;
                Lwt.return_unit)
              else if ethif_header.Ethernet.Packet.ethertype = `ARP then
                A.input a ethif_payload
              else Lwt.return_unit)
    in
    listener >|= function
    | Ok () -> Logs.info (fun m -> m "done!")
    | Error e -> Logs.err (fun m -> m "network listen failed! %a" N.pp_error e)
end
