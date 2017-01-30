open Lwt.Infix

let red fmt    = Fmt.strf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = Fmt.strf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Fmt.strf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = Fmt.strf ("\027[36m"^^fmt^^"\027[m")

module Main (C: Mirage_types_lwt.CONSOLE) (S: Mirage_types_lwt.STACKV4) = struct

  let start c s =
    S.listen_tcpv4 s ~port:8080 (fun flow ->
        let dst, dst_port = S.TCPV4.dst flow in
        C.log c (green "new tcp connection from %s %d"
                   (Ipaddr.V4.to_string dst) dst_port) >>= fun () ->
        S.TCPV4.read flow >>= function
        | Ok (`Data b) ->
          C.log c (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b))
          >>= fun () ->
          S.TCPV4.close flow
        | Ok `Eof -> C.log c (green "read: eof")
        | Error e -> C.log c (red "read: error %a" S.TCPV4.pp_error e)
      );

    S.listen s

end
