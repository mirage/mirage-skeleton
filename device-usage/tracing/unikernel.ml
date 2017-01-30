(* This unikernel is based on tracing documentation:
   https://mirage.io/wiki/profiling
*)

open Lwt.Infix
let target_ip = Ipaddr.V4.of_string_exn "10.0.0.1"

module Main (S: Mirage_types_lwt.STACKV4) = struct
  let buffer = Io_page.get 1 |> Io_page.to_cstruct

  let start s =
    let t = S.tcpv4 s in

    S.TCPV4.create_connection t (target_ip, 7001) >>= function
    | Error _err -> failwith "Connection to port 7001 failed"
    | Ok flow ->

    let payload = Cstruct.sub buffer 0 1 in
    Cstruct.set_char payload 0 '!';

    S.TCPV4.write flow payload >>= function
    | Error _ -> assert false
    | Ok () ->

    S.TCPV4.close flow
end
