open V1_LWT
open Lwt.Infix

let red fmt    = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let string_of_stream s =
  let s = List.map Cstruct.to_string s in
  (String.concat "" s)

module Main (C: CONSOLE) (N: NETWORK) (MClock : V1.MCLOCK) (Time: TIME) = struct
  module E = Ethif.Make(N)
  module A = Arpv4.Make(E)(MClock)(Time)
  module DC = Dhcp_config

  let log c s =
    Str.split_delim (Str.regexp "\n") s |>
    List.iter (fun line -> C.log c line)

  let of_interest dest net =
    Macaddr.compare dest (N.mac net) = 0 || not (Macaddr.is_unicast dest)

  let input_dhcp console clock net config leases buf =
    match (Dhcp_wire.pkt_of_buf buf (Cstruct.len buf)) with
    | Error e -> log console (red "Can't parse packet: %s" e);
      Lwt.return leases
    | Ok pkt ->
      let open Dhcp_server.Input in
      match (input_pkt config leases pkt (MClock.elapsed_ns clock |> Int64.to_float)) with
      | Silence -> Lwt.return leases
      | Update leases ->
        log console (blue "Received packet %s - updated lease database" (Dhcp_wire.pkt_to_string pkt));
        Lwt.return leases
      | Warning w ->
        log console (yellow "%s" w);
        Lwt.return leases
      | Dhcp_server.Input.Error e ->
        log console (red "%s" e);
        Lwt.return leases
      | Reply (reply, leases) ->
        log console (blue "Received packet %s" (Dhcp_wire.pkt_to_string pkt));
        N.write net (Dhcp_wire.buf_of_pkt reply)
        >>= fun () ->
        log console (blue "Sent reply packet %s" (Dhcp_wire.pkt_to_string reply));
        Lwt.return leases

  let start c net clock _time =
    let or_error _c name fn t =
      fn t >>= function
      | `Error _e -> Lwt.fail (Failure ("Error starting " ^ name))
      | `Ok t     -> Lwt.return t
    in

    (* Get an ARP stack *)
    or_error c "Ethif" E.connect net
    >>= fun e ->
    or_error c "Arpv4" (A.connect e) clock
    >>= fun a ->
    A.add_ip a DC.ip_address
    >>= fun () ->

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
          log c (red "Can't parse packet: %s" s);
          Lwt.return_unit
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
