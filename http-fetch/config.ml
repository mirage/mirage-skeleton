(* NOTE: requires mirage >= 2.5.0 *)
open Mirage

let net =
  try match Sys.getenv "NET" with
    | "direct" -> `Direct
    | _        -> `Socket
  with Not_found -> `Direct

let dhcp =
  try match Sys.getenv "DHCP" with
    | "0" -> `Static
    | _   -> `Dhcp
  with Not_found -> `Dhcp

let stack console =
  match net, dhcp with
  | `Direct, `Dhcp   -> direct_stackv4_with_dhcp console tap0
  | `Direct, `Static -> direct_stackv4_with_default_ipv4 console tap0
  | `Socket, _       -> socket_stackv4 console [Ipaddr.V4.any]

let client =
  foreign "Unikernel.Client" @@ console @-> resolver @-> conduit @-> job

let () =
  add_to_ocamlfind_libraries ["mirage-http"; "conduit.lwt-unix";];
  add_to_opam_packages ["mirage-http"];
  let sv4 = stack default_console in
  let res_dns = resolver_dns ~ns:(Ipaddr.V4.of_string_exn "8.8.8.8") sv4 in
  let conduit = conduit_direct sv4 in
  let job =  [ client $ default_console $ res_dns $ conduit ] in
  register "http-fetch" job
