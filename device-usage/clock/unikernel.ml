open Lwt.Infix

module Main
    (Time : Mirage_time.S)
    (PClock : Mirage_clock.PCLOCK)
    (MClock : Mirage_clock.MCLOCK) =
struct
  let start _time pclock mclock =
    let rec speak pclock mclock () =
      let current_time = PClock.now_d_ps pclock |> Ptime.v in
      let tz = PClock.current_tz_offset_s pclock in
      Logs.app (fun m ->
          m "%Lu nanoseconds have elapsed." (MClock.elapsed_ns mclock));
      Logs.app (fun m ->
          m "At the stroke, the time will be %a \x07 *BEEP*"
            (Ptime.pp_human ?tz_offset_s:tz ())
            current_time);
      Time.sleep_ns (Duration.of_sec 1) >>= fun () -> speak pclock mclock ()
    in
    speak pclock mclock ()
end
