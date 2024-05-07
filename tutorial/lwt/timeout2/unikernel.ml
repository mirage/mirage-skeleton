open Lwt.Infix

module Timeout2 (R : Mirage_random.S) = struct
  let timeout delay t =
    let tmout = Mirage_time.sleep_ns delay in
    Lwt.pick [ (tmout >|= fun () -> None); (t >|= fun v -> Some v) ]

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
