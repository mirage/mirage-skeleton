open Lwt.Infix

module Main (KV: Mirage_kv.RO) = struct

  let start kv =
    let our_secret = "foo\n" in
    KV.get kv (Mirage_kv.Key.v "secret") >|= function
    | Error e ->
      Logs.warn (fun f -> f "Could not compare the secret against a known constant: %a"
        KV.pp_error e)
    | Ok stored_secret ->
      match String.compare our_secret stored_secret with
      | 0 ->
        Logs.info (fun f -> f "Contents of extremely secret vital storage confirmed!")
      | _ ->
        Logs.warn (fun f -> f "The secret provided does not match!")
end
