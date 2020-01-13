open Lwt.Infix

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C: Mirage_console.S) (N: Mirage_net.S) (MClock : Mirage_clock.MCLOCK) (Time: Mirage_time.S) = struct
  module E = Ethernet.Make(N)
  module A = Arp.Make(E)(Time)
  module DC = Dhcp_config

  let log c s =
    Astring.String.cuts ~sep:"\n" s |>
    Lwt_list.iter_s (fun line -> C.log c line)

  let of_interest dest net =
    Macaddr.compare dest (N.mac net) = 0 || not (Macaddr.is_unicast dest)

  let input_dhcp console clock net config leases buf =
    match Dhcp_wire.pkt_of_buf buf (Cstruct.len buf) with
    | Error e ->
      log console (red "Can't parse packet: %s" e) >>= fun () ->
      Lwt.return leases
    | Ok pkt ->
      let open Dhcp_server.Input in
      let now = MClock.elapsed_ns clock |> Duration.to_sec |> Int32.of_int in
      match input_pkt config leases pkt now with
      | Silence -> Lwt.return leases
      | Update leases ->
        log console (blue "Received packet %s - updated lease database" (Dhcp_wire.pkt_to_string pkt)) >>= fun () ->
        Lwt.return leases
      | Warning w ->
        log console (yellow "%s" w) >>= fun () ->
        Lwt.return leases
      | Dhcp_server.Input.Error e ->
        log console (red "%s" e) >>= fun () ->
        Lwt.return leases
      | Reply (reply, leases) ->
        log console (blue "Received packet %s" (Dhcp_wire.pkt_to_string pkt)) >>= fun () ->
        N.write net ~size:(N.mtu net + Ethernet_wire.sizeof_ethernet) (Dhcp_wire.pkt_into_buf reply) >>= fun _ ->
        log console (blue "Sent reply packet %s" (Dhcp_wire.pkt_to_string reply)) >>= fun () ->
        Lwt.return leases

  let start c net clock _time =
    (* Get an ARP stack *)
    E.connect net >>= fun e ->
    A.connect e >>= fun a ->
    A.add_ip a DC.ip_address >>= fun () ->

    (* Build a dhcp server *)
    let config = Dhcp_server.Config.make
        ~hostname:DC.hostname
        ~default_lease_time:DC.default_lease_time
        ~max_lease_time:DC.max_lease_time
        ~hosts:DC.hosts
        ~addr_tuple:(DC.ip_address, N.mac net)
        ~network:DC.network
        ~range:DC.range
        ~options:DC.options
    in
    let leases = ref (Dhcp_server.Lease.make_db ()) in
    let listener = N.listen net ~header_size:Ethernet_wire.sizeof_ethernet (fun buf ->
        match Ethernet_packet.Unmarshal.of_cstruct buf with
        | Result.Error s ->
          log c (red "Can't parse packet: %s" s)
        | Result.Ok (ethif_header, ethif_payload) ->
          if of_interest ethif_header.Ethernet_packet.destination net &&
             Dhcp_wire.is_dhcp buf (Cstruct.len buf) then begin
            input_dhcp c clock net config !leases buf >>= fun new_leases ->
            leases := new_leases;
            Lwt.return_unit
          end else if ethif_header.Ethernet_packet.ethertype = `ARP then
            A.input a ethif_payload
          else Lwt.return_unit
      ) in
    listener
end
