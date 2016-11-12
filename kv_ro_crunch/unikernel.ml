open V1_LWT
open Lwt.Infix

let string_of_stream s =
  let s = List.map Cstruct.to_string s in
  Lwt.return (String.concat "" s)

module Main (Time: TIME) (C: CONSOLE) (X: KV_RO) (Y: KV_RO) = struct

  let start _time c x y =
    let rec aux () =
      X.read x "a" 0 4096 >>= fun vx ->
      Y.read y "a" 0 4096 >>= fun vy ->
      begin match vx, vy with
        | `Ok sx, `Ok sy ->
          string_of_stream sx >>= fun sx ->
          string_of_stream sy >>= fun sy ->
          if sx = sy then
            C.log c "YES!"
          else
            C.log c "NO!"
        | _ ->
          C.log c "NO! NO!"
      end >>= fun () ->
      Time.sleep_ns (Duration.of_sec 1) >>= fun () ->
      aux ()
    in
    aux ()
end
