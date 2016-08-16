module Main (Console : V1_LWT.CONSOLE) (PClock : V1_LWT.PCLOCK) (MClock : V1_LWT.MCLOCK) = struct
  let str_of_time (posix_time, timezone) =
    Format.asprintf "%a" (Ptime.pp_human ?tz_offset_s:timezone ()) posix_time

  let start console pclock mclock =
    let rec speak () =
      let time = PClock.now_d_ps pclock |> Ptime.v in
      let tz = PClock.current_tz_offset_s pclock in
      Console.log console (Printf.sprintf "%Lu nanoseconds have elapsed. At the chime, the time will be %s. \b *DING*" (Mclock.elapsed_ns mclock) @@ str_of_time (time, tz));
      speak ()
    in
    speak ()
end
