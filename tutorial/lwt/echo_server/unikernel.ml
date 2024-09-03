open Lwt.Infix

module Echo_server (Time : Mirage_time.S) (R : Mirage_crypto_rng_mirage.S) = struct
  let generate n = R.generate n

  let read_line () =
    Time.sleep_ns (Duration.of_ms (Randomconv.int ~bound:2500 generate))
    >|= fun () -> String.make (Randomconv.int ~bound:20 generate) 'a'

  let start _time _r =
    let rec echo_server = function
      | 0 -> Lwt.return ()
      | n ->
          read_line () >>= fun s ->
          Logs.info (fun m -> m "%s" s);
          echo_server (n - 1)
    in
    echo_server 10
end
