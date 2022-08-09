(* This unikernel is based on tracing documentation:
   https://mirage.io/wiki/profiling
*)

open Lwt.Infix

let target_ip = Ipaddr.of_string_exn "10.0.0.1"

module Main (S : Tcpip.Stack.V4V6) = struct
  let buffer = Io_page.get 1 |> Io_page.to_cstruct

  let start s =
    let t = S.tcp s in

    S.TCP.create_connection t (target_ip, 7001) >>= function
    | Error _err -> failwith "Connection to port 7001 failed"
    | Ok flow -> (
        let payload = Cstruct.sub buffer 0 1 in
        Cstruct.set_char payload 0 '!';

        S.TCP.write flow payload >>= function
        | Error _ -> assert false
        | Ok () -> S.TCP.close flow)
end
