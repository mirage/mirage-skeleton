open Lwt.Infix

let timeout delay t =
  Mirage_sleep.ns delay >>= fun () ->
  match Lwt.state t with
  | Lwt.Sleep ->
      Lwt.cancel t;
      Lwt.return None
  | Lwt.Return v -> Lwt.return (Some v)
  | Lwt.Fail ex -> Lwt.fail ex

let start () =
  let t =
    let r = Randomconv.int ~bound:3000 Mirage_crypto_rng.generate in
    Mirage_sleep.ns (Duration.of_ms r) >|= fun () -> "Heads"
  in
  timeout (Duration.of_sec 2) t >|= function
  | None -> Logs.info (fun m -> m "Cancelled")
  | Some v -> Logs.info (fun m -> m "Returned %S" v)
