open Lwt.Infix

let generate n = Mirage_crypto_rng.generate n

let read_line () =
  Mirage_sleep.ns (Duration.of_ms (Randomconv.int ~bound:2500 generate))
  >|= fun () -> String.make (Randomconv.int ~bound:20 generate) 'a'

let start () =
  let rec echo_server = function
    | 0 -> Lwt.return ()
    | n ->
      read_line () >>= fun s ->
      Logs.info (fun m -> m "%s" s);
      echo_server (n - 1)
  in
  echo_server 10

