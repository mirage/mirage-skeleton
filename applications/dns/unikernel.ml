module Make (Console : Mirage_console.S) (DNS : Dns_client_mirage.S) = struct
  let log console fmt =
    Fmt.kstr (Console.log console) fmt

  let start console dns =
    let ( >>= ) = Result.bind in
    match Domain_name.(of_string (Key_gen.domain_name ()) >>= host) with
    | Error (`Msg err) -> failwith err
    | Ok domain_name ->
      let open Lwt.Infix in
      DNS.gethostbyname dns domain_name >>= function
      | Ok ipv4 ->
        log console "%a: %a" Domain_name.pp domain_name Ipaddr.V4.pp ipv4
      | Error (`Msg err) -> failwith err
end
