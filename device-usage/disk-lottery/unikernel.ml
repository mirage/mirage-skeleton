open Lwt.Infix
open Cmdliner

let reset_all =
  let doc = Arg.info ~doc:"Reset all state on disk and quit" [ "reset-all" ] in
  Mirage_runtime.register_arg Arg.(value & flag doc)

let sector =
  let doc = Arg.info ~doc:"Sector to read and write game state to" [ "slot" ] in
  Mirage_runtime.register_arg Arg.(value & opt int64 0L doc)

let reset =
  let doc =
    Arg.info
      ~doc:
        "Reset the state on disk at the specified slot (using --slot, default \
         0) and quit"
      [ "reset" ]
  in
  Mirage_runtime.register_arg Arg.(value & flag doc)

module Main (Disk : Mirage_block.S) (Random : Mirage_crypto_rng_mirage.S) =
struct
  let write_state disk info sector state =
    let buf = Cstruct.create info.Mirage_block.sector_size in
    Lotto.marshal buf state;
    Disk.write disk sector [ buf ] >>= fun r ->
    match r with
    | Ok () -> Lwt.return_unit
    | Error e ->
        Logs.err (fun m ->
            m "Error writing new state: %a" Disk.pp_write_error e);
        exit 6

  let read_state disk info sector =
    let buf = Cstruct.create info.Mirage_block.sector_size in
    Disk.read disk sector [ buf ] >|= fun r ->
    (match r with
    | Ok () -> ()
    | Error e ->
        Logs.err (fun m -> m "Error reading: %a" Disk.pp_error e);
        exit 6);
    match Lotto.unmarshal buf with
    | Ok state -> state
    | Error (`Msg e) ->
        Logs.err (fun m -> m "Error reading state: %s" e);
        exit 6

  let play disk info sector =
    read_state disk info sector >>= fun state ->
    let draw = String.get_int32_be (Random.generate 4) 0 in
    let game, state = Lotto.play state draw in
    Logs.app (fun m -> m "%a" Lotto.pp_game game);
    Logs.info (fun m -> m "Saving new game state...");
    write_state disk info sector state >|= fun () ->
    Logs.info (fun m -> m "Done!");
    Logs.app (fun m -> m "Thank you for playing! Exiting...")

  let reset_game disk info sector =
    write_state disk info sector Lotto.initial_state

  let reset_all_games disk info =
    let rec loop sector =
      if sector < info.Mirage_block.size_sectors then
        reset_game disk info sector >>= fun () -> loop (Int64.succ sector)
      else Lwt.return_unit
    in
    loop 0L

  let start disk _random =
    Disk.get_info disk >>= fun info ->
    if info.sector_size < Lotto.len then (
      Logs.err (fun m ->
          m "Sector size %d is too short for storing lottery data!"
            info.sector_size);
      exit 5);
    if sector () < 0L || sector () >= info.size_sectors then (
      Logs.err (fun m -> m "Invalid sector %Ld" (sector ()));
      exit 5);
    if reset_all () then
      reset_all_games disk info >|= fun () ->
      Logs.app (fun m -> m "All %Ld game slots reset." info.size_sectors)
    else if reset () then
      reset_game disk info (sector ()) >|= fun () ->
      Logs.app (fun m -> m "Reset game slot %Ld." ((sector ())))
    else play disk info (sector ())
end
