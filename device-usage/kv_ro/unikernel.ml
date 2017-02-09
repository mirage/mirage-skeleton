open Lwt.Infix

module Main (KV: Mirage_kv_lwt.RO) = struct

  let read_whole_file kv key =
    KV.size kv key >>= function
    | Error e -> Lwt.return @@ Error e
    | Ok size -> KV.read kv key 0L size

  let start kv =
    let our_secret = Cstruct.of_string "foo\n" in
    read_whole_file kv "secret" >|= function
    | Error e ->
      Logs.warn (fun f -> f "Could not compare the secret against a known constant: %a"
        KV.pp_error e)
    | Ok stored_secret ->
      match Cstruct.compare our_secret (Cstruct.concat stored_secret) with
      | 0 ->
        Logs.info (fun f -> f "Contents of extremely secret vital storage confirmed!")
      | _ ->
        Logs.warn (fun f -> f "The secret provided does not match!")
end
