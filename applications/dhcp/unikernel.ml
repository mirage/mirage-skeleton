open Mirage_types_lwt
open Lwt.Infix

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C: CONSOLE) (N: NETWORK) (MClock : Mirage_types.MCLOCK) (Time: TIME) = struct
  module E = Ethif.Make(N)
  module A = Arpv4.Make(E)(MClock)(Time)
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
      match input_pkt config leases pkt (MClock.elapsed_ns clock |> Int64.to_float) with
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
        N.write net (Dhcp_wire.buf_of_pkt reply) >>= fun _ ->
        log console (blue "Sent reply packet %s" (Dhcp_wire.pkt_to_string reply)) >>= fun () ->
        Lwt.return leases

  let start c net clock _time =
    (* Get an ARP stack *)
    E.connect net >>= fun e ->
    A.connect e clock >>= fun a ->
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
    let listener = N.listen net (fun buf ->
        match Ethif_packet.Unmarshal.of_cstruct buf with
        | Result.Error s ->
          log c (red "Can't parse packet: %s" s)
        | Result.Ok (ethif_header, ethif_payload) ->
          if of_interest ethif_header.Ethif_packet.destination net &&
             Dhcp_wire.is_dhcp buf (Cstruct.len buf) then begin
            input_dhcp c clock net config !leases buf >>= fun new_leases ->
            leases := new_leases;
            Lwt.return_unit
          end else if ethif_header.Ethif_packet.ethertype = Ethif_wire.ARP then
            A.input a ethif_payload
          else Lwt.return_unit
      ) in
    listener
end
