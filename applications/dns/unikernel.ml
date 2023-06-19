module Make (DNS : Dns_client_mirage.S) = struct
  let start dns =
    let ( >>= ) = Result.bind in
    match Domain_name.(of_string (Key_gen.domain_name ()) >>= host) with
    | Error (`Msg err) -> failwith err
    | Ok domain_name -> (
        let open Lwt.Infix in
        DNS.gethostbyname dns domain_name >|= function
        | Ok ipv4 ->
          Logs.info (fun m -> m "%a: %a" Domain_name.pp domain_name Ipaddr.V4.pp ipv4)
        | Error (`Msg err) -> failwith err)
end
