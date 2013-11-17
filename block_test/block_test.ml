open Lwt
open Printf
open OS

let tests_started = ref 0
let tests_finished = ref 0

let ( >>= ) x f = x >>= function
  | `Error _ -> fail (Failure "error")
  | `Ok x -> f x

let fill_with_pattern x =
  let phrase = "All work and no play makes Dave a dull boy.\n" in
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

let check_single_sector_write_beginning kind id =
  incr tests_started;
  lwt module_b = OS.Block.find kind in
  let module B = (val module_b: OS.Block.S) in
  B.connect id >>= fun b ->
  let page = Io_page.(to_cstruct (get 1)) in
  lwt info = B.get_info b in
  let sector = Cstruct.sub page 0 info.B.sector_size in
  fill_with_pattern sector;
  B.write b 0L [ sector ] >>= fun () ->
  let page' = Io_page.(to_cstruct (get 1)) in
  let sector' = Cstruct.sub page' 0 info.B.sector_size in
  fill_with_zeroes sector';
  B.read b 0L [ sector' ] >>= fun () ->
  check_equal sector sector';
  incr tests_finished;
  return ()

let check_single_sector_write_end module_b b =
  false

let check_single_sector_contiguous_writes module_b b =
  false

let check_multi_sector_writes module_b b =
  false

let main _ =
  lwt () = Blkfront_init.register () in
  lwt module_b = OS.Block.find "local" in
  let module B = (val module_b: OS.Block.S) in
  B.connect "51712" >>= fun b ->
  lwt info = B.get_info b in
  printf "sectors = %Ld\nread_write=%b\nsector_size=%d\n%!"
    info.B.size_sectors info.B.read_write info.B.sector_size;
  
  lwt () = check_single_sector_write_beginning "local" "51712" in
  printf "Test sequence finished\n";
  printf "Total tests started:  %d\n" !tests_started;
  printf "Total tests finished: %d\n%!" !tests_finished;
  OS.Time.sleep 5.
