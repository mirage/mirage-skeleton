open Lwt.Infix
open Printf

module Main (B : Mirage_block.S) = struct
  let log_src = Logs.Src.create "block" ~doc:"block tester"

  module Log = (val Logs.src_log log_src : Logs.LOG)

  let tests_started = ref 0
  let tests_passed = ref 0
  let tests_failed = ref 0

  let check_equal a b =
    if not (Cstruct.equal a b) then
      Log.warn (fun f ->
          f "Buffers unequal: %S vs %S" (Cstruct.to_string a)
            (Cstruct.to_string b))

  let rec fill_with_pattern x phrase =
    assert (String.length phrase > 0);
    if Cstruct.length x > 0 then (
      let l = min (String.length phrase) (Cstruct.length x) in
      Cstruct.blit_from_string phrase 0 x 0 l;
      fill_with_pattern (Cstruct.shift x l) phrase)

  let alloc_dull_boy sector_size n =
    let b = Cstruct.create_unsafe (n * sector_size) in
    List.init n (fun i ->
        let sector = Cstruct.sub b (i * sector_size) sector_size in
        let phrase =
          sprintf "%d: All work and no play makes Dave a dull boy.\n" i
        in
        fill_with_pattern sector phrase;
        sector)

  let check_sector_write b offset length =
    Log.debug (fun f -> f "writing %d sector(s) at %Ld\n" length offset);
    incr tests_started;
    B.get_info b >>= fun info ->
    let sectors = alloc_dull_boy info.sector_size length in
    B.write b offset sectors >>= fun r ->
    (match r with
    | Ok () -> ()
    | Error e ->
        Log.err (fun m -> m "%a" B.pp_write_error e);
        exit 2);
    let sectors' =
      let b = Cstruct.create (length * info.sector_size) in
      List.init length (fun i ->
          Cstruct.sub b (i * info.sector_size) info.sector_size)
    in
    B.read b offset sectors' >>= fun r ->
    (match r with
    | Ok () -> ()
    | Error e ->
        Log.err (fun m -> m "%a" B.pp_error e);
        exit 2);
    List.iter2 (fun a b -> check_equal a b) sectors sectors';
    incr tests_passed;
    Lwt.return_unit

  let check_sector_write_failure b offset length =
    Log.debug (fun f -> f "writing %d sectors at %Ld\n" length offset);
    incr tests_started;
    B.get_info b >>= fun info ->
    let sectors = alloc_dull_boy info.sector_size length in
    Log.debug (fun f ->
        f "Expecting error output from the following operation...");
    B.write b offset sectors >|= function
    | Ok () ->
        Log.err (fun f -> f "-- expected failure; got success\n%!");
        incr tests_failed
    | Error _ -> incr tests_passed

  let check_sector_read_failure b offset length =
    printf "reading %d sectors at %Ld\n%!" length offset;
    incr tests_started;
    B.get_info b >>= fun info ->
    let sectors = [ Cstruct.create (length * info.sector_size) ] in
    Log.debug (fun f ->
        f "Expecting error output from the following operation...");
    B.read b offset sectors >|= function
    | Ok () ->
        Log.err (fun f -> f "-- expected failure; got success\n%!");
        incr tests_failed
    | Error _ -> incr tests_passed

  let start b =
    B.get_info b >>= fun info ->
    Log.info (fun f -> f "%a" Mirage_block.pp_info info);

    check_sector_write b 0L 1 >>= fun () ->
    check_sector_write b (Int64.sub info.size_sectors 1L) 1 >>= fun () ->
    check_sector_write b 0L 2 >>= fun () ->
    check_sector_write b (Int64.sub info.size_sectors 2L) 2 >>= fun () ->
    check_sector_write b 0L 12 >>= fun () ->
    check_sector_write b (Int64.sub info.size_sectors 12L) 12 >>= fun () ->
    check_sector_write_failure b info.size_sectors 1 >>= fun () ->
    check_sector_write_failure b (Int64.sub info.size_sectors 11L) 12
    >>= fun () ->
    check_sector_read_failure b info.size_sectors 1 >>= fun () ->
    check_sector_read_failure b (Int64.sub info.size_sectors 11L) 12
    >|= fun () ->
    Log.info (fun f -> f "Test sequence finished\n");
    Log.info (fun f -> f "Total tests started: %d\n" !tests_started);
    Log.info (fun f -> f "Total tests passed:  %d\n" !tests_passed);
    Log.info (fun f -> f "Total tests failed:  %d\n%!" !tests_failed)
end
