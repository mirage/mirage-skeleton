open Lwt
open Printf
open OS
open Mirage_types.V1

module Main (C: CONSOLE)(B: BLOCK) = struct

let tests_started = ref 0
let tests_passed = ref 0
let tests_failed = ref 0

let ( >>= ) x f = x >>= function
  | `Error _ -> fail (Failure "error")
  | `Ok x -> f x

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
    Printf.printf "Buffers are not equal:\n";
    Printf.printf "First buffer:\n";
    Printf.printf "%s\n" (String.escaped (Cstruct.to_string a));
    Printf.printf "Second buffer:\n";
    Printf.printf "%s\n%!" (String.escaped (Cstruct.to_string b))
  end

let alloc sector_size n =
  let rec loop = function
    | 0 -> []
    | n ->
      let page = Io_page.(to_cstruct (get 1)) in
      let phrase = Printf.sprintf "%d: All work and no play makes Dave a dull boy.\n" n in
      let sector = Cstruct.sub page 0 sector_size in
      fill_with_pattern sector phrase;
      sector :: (loop (n-1)) in
  loop n

let check_sector_write b kind id offset length =
  printf "writing %d sectors at %Ld\n" length offset;
  incr tests_started;
  lwt info = B.get_info b in
  let sectors = alloc info.B.sector_size length in
  B.write b offset sectors >>= fun () ->
  let sectors' = alloc info.B.sector_size length in
  List.iter fill_with_zeroes sectors';
  B.read b offset sectors' >>= fun () ->
  List.iter (fun (a, b) -> check_equal a b) (List.combine sectors sectors');
  incr tests_passed;
  return ()

let check_sector_write_failure b kind id offset length =
  printf "writing %d sectors at %Ld\n" length offset;
  incr tests_started;
  lwt info = B.get_info b in
  let sectors = alloc info.B.sector_size length in
  match_lwt B.write b offset sectors with
  | `Ok () ->
    printf "-- expected failure; got success\n%!";
    incr tests_failed;
    return ()
  | `Error _ ->
    incr tests_passed;
    return ()

let check_sector_read_failure b kind id offset length =
  printf "reading %d sectors at %Ld\n" length offset;
  incr tests_started;
  lwt info = B.get_info b in
  let sectors = alloc info.B.sector_size length in
  match_lwt B.read b offset sectors with
  | `Ok () ->
    printf "-- expected failure; got success\n%!";
    incr tests_failed;
    return ()
  | `Error _ ->
    incr tests_passed;
    return ()

let start console b =
  lwt info = B.get_info b in
  printf "sectors = %Ld\nread_write=%b\nsector_size=%d\n%!"
    info.B.size_sectors info.B.read_write info.B.sector_size;

  lwt () = check_sector_write b "local" "51712" 0L 1 in
  lwt () = check_sector_write b "local" "51712" (Int64.sub info.B.size_sectors 1L) 1 in
  lwt () = check_sector_write b "local" "51712" 0L 2 in
  lwt () = check_sector_write b "local" "51712" (Int64.sub info.B.size_sectors 2L) 2 in
  lwt () = check_sector_write b "local" "51712" 0L 12 in
  lwt () = check_sector_write b "local" "51712" (Int64.sub info.B.size_sectors 12L) 12 in

  lwt () = check_sector_write_failure b "local" "51712" info.B.size_sectors 1 in
  lwt () = check_sector_write_failure b "local" "51712" (Int64.sub info.B.size_sectors 11L) 12 in
  lwt () = check_sector_read_failure b "local" "51712" info.B.size_sectors 1 in
  lwt () = check_sector_read_failure b "local" "51712" (Int64.sub info.B.size_sectors 11L) 12 in

  printf "Test sequence finished\n";
  printf "Total tests started: %d\n" !tests_started;
  printf "Total tests passed:  %d\n" !tests_passed;
  printf "Total tests failed:  %d\n%!" !tests_failed;
  OS.Time.sleep 5.
end
