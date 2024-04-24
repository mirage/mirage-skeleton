open Lwt.Infix

let log = Logs.Src.create "speaking clock" ~doc:"At the third stroke..."

module Log = (val Logs.src_log log : Logs.LOG)

module Main (_ : sig end) = struct
  let str_of_time (posix_time, timezone) =
    Format.asprintf "%a" (Ptime.pp_human ?tz_offset_s:timezone ()) posix_time

  let start () () () =
    let rec speak () =
      let current_time = Mirage_clock.Pclock.now_d_ps () |> Ptime.v in
      let tz = Mirage_clock.Pclock.current_tz_offset_s () in
      let str =
        Printf.sprintf
          "%Lu nanoseconds have elapsed. \n\
          \ At the stroke, the time will be %s \x07 *BEEP*"
          (Mirage_clock.Mclock.elapsed_ns ())
        @@ str_of_time (current_time, tz)
      in
      Log.info (fun f -> f "%s" str);
      Mirage_time.sleep_ns 1_000_000_000L >>= fun () -> speak ()
    in
    speak ()
end
