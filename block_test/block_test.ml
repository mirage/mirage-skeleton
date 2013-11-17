open Lwt
open Printf
open OS

let tests_started = ref 0
let tests_finished = ref 0

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

let check_sector_write kind id offset length =
  printf "writing %d sectors at %Ld\n" length offset;
  incr tests_started;
  lwt module_b = OS.Block.find kind in
  let module B = (val module_b: OS.Block.S) in
  B.connect id >>= fun b ->
  lwt info = B.get_info b in
  let rec alloc = function
    | 0 -> []
    | n ->
      let page = Io_page.(to_cstruct (get 1)) in
      let phrase = Printf.sprintf "%d: All work and no play makes Dave a dull boy.\n" n in
      let sector = Cstruct.sub page 0 info.B.sector_size in
      fill_with_pattern sector phrase;
      sector :: (alloc (n-1)) in
  let sectors = alloc length in
  B.write b offset sectors >>= fun () ->
  let sectors' = alloc length in
  List.iter fill_with_zeroes sectors';
  B.read b offset sectors' >>= fun () ->
  List.iter (fun (a, b) -> check_equal a b) (List.combine sectors sectors');
  incr tests_finished;
  return ()

let main _ =
  lwt () = Blkfront_init.register () in
  lwt module_b = OS.Block.find "local" in
  let module B = (val module_b: OS.Block.S) in
  B.connect "51712" >>= fun b ->
  lwt info = B.get_info b in
  printf "sectors = %Ld\nread_write=%b\nsector_size=%d\n%!"
    info.B.size_sectors info.B.read_write info.B.sector_size;
 
  lwt () = check_sector_write "local" "51712" 0L 1 in
  lwt () = check_sector_write "local" "51712" (Int64.sub info.B.size_sectors 1L) 1 in
  lwt () = check_sector_write "local" "51712" 0L 2 in
  lwt () = check_sector_write "local" "51712" (Int64.sub info.B.size_sectors 2L) 2 in
  lwt () = check_sector_write "local" "51712" 0L 12 in
  lwt () = check_sector_write "local" "51712" (Int64.sub info.B.size_sectors 12L) 12 in
  printf "Test sequence finished\n";
  printf "Total tests started:  %d\n" !tests_started;
  printf "Total tests finished: %d\n%!" !tests_finished;
  OS.Time.sleep 5.
