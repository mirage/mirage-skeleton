open Lwt.Infix

let start () =
  let rec speak () =
    let current_time = Mirage_ptime.now () in
    let tz = Mirage_ptime.current_tz_offset_s () in
    Logs.app (fun m ->
        m "%Lu nanoseconds have elapsed." (Mirage_mtime.elapsed_ns ()));
    Logs.app (fun m ->
        m "At the stroke, the time will be %a \x07 *BEEP*"
          (Ptime.pp_human ?tz_offset_s:tz ())
          current_time);
    Mirage_sleep.ns (Duration.of_sec 1) >>= fun () ->
    speak ()
  in
  speak ()
