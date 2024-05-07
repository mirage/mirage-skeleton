open Lwt.Infix

module Timeout1 (R : Mirage_random.S) = struct
  let timeout delay t =
    Mirage_time.sleep_ns delay >>= fun () ->
    match Lwt.state t with
    | Lwt.Sleep ->
        Lwt.cancel t;
        Lwt.return None
    | Lwt.Return v -> Lwt.return (Some v)
    | Lwt.Fail ex -> Lwt.fail ex

  let generate i = R.generate i

  let start _r _time =
    let t =
      Mirage_time.sleep_ns (Duration.of_ms (Randomconv.int ~bound:3000 generate))
      >|= fun () -> "Heads"
    in
    timeout (Duration.of_sec 2) t >|= function
    | None -> Logs.info (fun m -> m "Cancelled")
    | Some v -> Logs.info (fun m -> m "Returned %S" v)
end
