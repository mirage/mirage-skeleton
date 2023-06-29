open Lwt.Infix
open Cmdliner

let port =
  let doc =
    Arg.info ~doc:"The TCP port on which to listen for incoming connections."
      [ "port" ]
  in
  let key = Arg.(value & opt int 8080 doc) in
  Mirage_runtime.key key

module Main (S : Tcpip.Stack.V4V6) = struct
  let start s =
    let port = port () in
    S.TCP.listen (S.tcp s) ~port (fun flow ->
        let dst, dst_port = S.TCP.dst flow in
        Logs.info (fun f ->
            f "new tcp connection from IP %s on port %d" (Ipaddr.to_string dst)
              dst_port);
        S.TCP.read flow >>= function
        | Ok `Eof ->
            Logs.info (fun f -> f "Closing connection!");
            Lwt.return_unit
        | Error e ->
            Logs.warn (fun f ->
                f "Error reading data from established connection: %a"
                  S.TCP.pp_error e);
            Lwt.return_unit
        | Ok (`Data b) ->
            Logs.debug (fun f ->
                f "read: %d bytes:\n%s" (Cstruct.length b) (Cstruct.to_string b));
            S.TCP.close flow);

    S.listen s
end
