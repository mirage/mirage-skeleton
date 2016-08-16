module Main (Console : V1_LWT.CONSOLE) (PClock : V1_LWT.PCLOCK) = struct
  let str_of_time (posix_time, timezone) =
    Format.asprintf "%a" (Ptime.pp_human ?tz_offset_s:timezone ()) posix_time

  let start console pclock =
    let rec speak () =
      let time = PClock.now_d_ps pclock |> Ptime.v in
      let tz = PClock.current_tz_offset_s pclock in
      Console.log console (Printf.sprintf "At the chime, the time will be %s. \b" @@ str_of_time (time, tz));
      speak ()
    in
    speak ()
end
