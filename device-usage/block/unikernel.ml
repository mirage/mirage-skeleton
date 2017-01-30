open Lwt.Infix
open Printf
open Mirage_types_lwt

module Main (Time: TIME)(B: BLOCK) = struct
  let log_src = Logs.Src.create "block" ~doc:"block tester"
  module Log = (val Logs.src_log log_src : Logs.LOG)

  let tests_started = ref 0
  let tests_passed = ref 0
  let tests_failed = ref 0

  let ( >>*= ) x f = x >>= function
    | Error _ -> Lwt.fail (Failure "error")
    | Ok x -> f x

  let fill_with_pattern x phrase =
    for i = 0 to Cstruct.len x - 1 do
      Cstruct.set_char x i phrase.[i mod (String.length phrase)]
    done

  let fill_with_zeroes x =
    for i = 0 to Cstruct.len x - 1 do
      Cstruct.set_uint8 x i 0
    done

  let cstruct_equal a b =
    let check_contents a b =
      try
        for i = 0 to Cstruct.len a - 1 do
          let a' = Cstruct.get_char a i in
          let b' = Cstruct.get_char b i in
          if a' <> b' then raise Not_found (* won't escape *)
        done;
        true
      with _ -> false in
    (Cstruct.len a = (Cstruct.len b)) && (check_contents a b)

  let check_equal a b =
    if not(cstruct_equal a b) then begin
      Log.warn (fun f -> f "Buffers unequal: %S vs %S"
        (Cstruct.to_string a) (Cstruct.to_string b))
    end

  let alloc sector_size n =
    let rec loop = function
      | 0 -> []
      | n ->
        let page = Io_page.(to_cstruct (get 1)) in
        let phrase = sprintf "%d: All work and no play makes Dave a dull boy.\n" n in
        let sector = Cstruct.sub page 0 sector_size in
        fill_with_pattern sector phrase;
        sector :: (loop (n-1)) in
    loop n

  open Mirage_block

  let check_sector_write b _kind _id offset length =
    Log.debug (fun f -> f "writing %d sectors at %Ld\n" length offset);
    incr tests_started;
    B.get_info b >>= fun info ->
    let sectors = alloc info.sector_size length in
    B.write b offset sectors >>*= fun () ->
    let sectors' = alloc info.sector_size length in
    List.iter fill_with_zeroes sectors';
    B.read b offset sectors' >>*= fun () ->
    List.iter (fun (a, b) -> check_equal a b) (List.combine sectors sectors');
    incr tests_passed;
    Lwt.return_unit

  let check_sector_write_failure b _kind _id offset length =
    Log.debug (fun f -> f "writing %d sectors at %Ld\n" length offset);
    incr tests_started;
    B.get_info b >>= fun info ->
    let sectors = alloc info.sector_size length in
    Log.err (fun f -> f "Expecting error output from the following operation...");
    B.write b offset sectors >|= function
    | Ok () ->
      Log.err (fun f -> f "-- expected failure; got success\n%!");
      incr tests_failed
    | Error _ ->
      incr tests_passed

  let check_sector_read_failure b _kind _id offset length =
    printf "reading %d sectors at %Ld\n" length offset;
    incr tests_started;
    B.get_info b >>= fun info ->
    let sectors = alloc info.sector_size length in
    Log.err (fun f -> f "Expecting error output from the following operation...");
    B.read b offset sectors >|= function
    | Ok () ->
      Log.err (fun f -> f "-- expected failure; got success\n%!");
      incr tests_failed
    | Error _ ->
      incr tests_passed

  let start _time b () =
    B.get_info b >>= fun info ->
    (* FIXME(samoht): this should probably move into
       Mirage_block.pp_info *)
    Log.info (fun f -> f "sectors = %Ld\nread_write=%b\nsector_size=%d\n%!"
      info.size_sectors info.read_write info.sector_size);

    check_sector_write b "local" "51712" 0L 1
    >>= fun () ->
    check_sector_write b "local" "51712" (Int64.sub info.size_sectors 1L) 1
    >>= fun () ->
    check_sector_write b "local" "51712" 0L 2
    >>= fun () ->
    check_sector_write b "local" "51712" (Int64.sub info.size_sectors 2L) 2
    >>= fun () ->
    check_sector_write b "local" "51712" 0L 12
    >>= fun () ->
    check_sector_write b "local" "51712" (Int64.sub info.size_sectors 12L) 12
    >>= fun () ->

    check_sector_write_failure b "local" "51712" info.size_sectors 1
    >>= fun () ->
    check_sector_write_failure b "local" "51712" (Int64.sub info.size_sectors 11L) 12
    >>= fun () ->
    check_sector_read_failure b "local" "51712" info.size_sectors 1
    >>= fun () ->

    check_sector_read_failure b "local" "51712" (Int64.sub info.size_sectors 11L) 12
    >>= fun () ->

    Log.info (fun f -> f "Test sequence finished\n");
    Log.info (fun f -> f "Total tests started: %d\n" !tests_started);
    Log.info (fun f -> f "Total tests passed:  %d\n" !tests_passed);
    Log.info (fun f -> f "Total tests failed:  %d\n%!" !tests_failed);
    Time.sleep_ns (Duration.of_sec 5)

end
