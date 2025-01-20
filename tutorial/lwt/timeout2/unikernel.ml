open Lwt.Infix

let timeout delay t =
  let tmout = Mirage_sleep.ns delay in
  Lwt.pick [ (tmout >|= fun () -> None); (t >|= fun v -> Some v) ]

let start () =
  let t =
    let r = Randomconv.int ~bound:3000 Mirage_crypto_rng.generate in
    Mirage_sleep.ns (Duration.of_ms r) >|= fun () ->
    "Heads"
  in
  timeout (Duration.of_sec 2) t >|= function
  | None -> Logs.info (fun m -> m "Cancelled")
  | Some v -> Logs.info (fun m -> m "Returned %S" v)
