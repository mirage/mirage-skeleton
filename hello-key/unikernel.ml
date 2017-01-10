open Lwt.Infix

let log = Logs.Src.create "hello" ~doc:"Hello? Hello!"
module Log = (val Logs.src_log log : Logs.LOG)

module Hello (PClock: Mirage_types.PCLOCK) = struct

  module Logs_reporter = Mirage_logs.Make(PClock)

  let start pclock =

    Logs.(set_level (Some Info));
    Logs_reporter.(create pclock |> run) @@ fun () ->

    let hello = Key_gen.hello () in

    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        Log.info (fun f -> f "%s" hello);
        OS.Time.sleep_ns (Duration.of_sec 1) >>= fun () ->
        loop (n-1)
    in
    loop 4

end
