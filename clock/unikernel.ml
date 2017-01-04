open Lwt.Infix

let log = Logs.Src.create "speaking clock" ~doc:"At the third stroke..."
module Log = (val Logs.src_log log : Logs.LOG)

module Main (Time: V1.TIME) (PClock: V1.PCLOCK) (MClock: V1.MCLOCK) = struct

  module Logs_reporter = Mirage_logs.Make(PClock)

  let str_of_time (posix_time, timezone) =
    Format.asprintf "%a" (Ptime.pp_human ?tz_offset_s:timezone ()) posix_time

  let start _time pclock mclock =

    Logs.(set_level (Some Info));
    Logs_reporter.(create pclock |> run) @@ fun () ->

    let rec speak pclock mclock () =
      let current_time = PClock.now_d_ps pclock |> Ptime.v in
      let tz = PClock.current_tz_offset_s pclock in
      let str =
        Printf.sprintf
          "%Lu nanoseconds have elapsed. \n\
          \ At the stroke, the time will be %s \x07 *BEEP*"
          (Mclock.elapsed_ns mclock) @@ str_of_time (current_time, tz)
      in
      Log.info (fun f -> f "%s" str);
      OS.Time.sleep_ns 1_000_000_000L >>= fun () ->
      speak pclock mclock ()
    in
    speak pclock mclock ()

end
