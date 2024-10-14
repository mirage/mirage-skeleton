open Cmdliner

let domain_name =
  let name_c =
    Arg.conv
      ( (fun s -> Result.bind (Domain_name.of_string s) Domain_name.host),
        Domain_name.pp )
  in
  let doc = Arg.info ~doc:"The domain-name to resolve." [ "domain-name" ] in
  Mirage_runtime.register_arg Arg.(required & opt (some name_c) None doc)

module Make (DNS : Dns_client_mirage.S) = struct
  let start dns =
    let open Lwt.Infix in
    DNS.gethostbyname dns (domain_name ()) >|= function
    | Ok ipv4 ->
        Logs.info (fun m ->
            m "%a: %a" Domain_name.pp (domain_name ()) Ipaddr.V4.pp ipv4)
    | Error (`Msg err) -> failwith err
end
