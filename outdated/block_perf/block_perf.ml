open Lwt
open Printf

open Perf

let main _ =
  lwt () = Blkfront.register () in
  let finished_t, u = Lwt.task () in
  let listen_t = OS.Devices.listen (fun id ->
    OS.Devices.find_blkif id >>=
    function
    | None -> return ()
    | Some blkif -> Lwt.wakeup u blkif; return ()
  ) in
  (* Get one device *)
  lwt blkif = finished_t in
  (* Cancel the listening thread *)
  Lwt.cancel listen_t;
  printf "ID: %s\n%!" blkif#id;
  printf "Connected block device\n%!";
  printf "Total device size = %Ld\nSector size = %d\n%!" blkif#size blkif#sector_size;
  printf "Device is read%s\n%!" (if blkif#readwrite then "/write" else "-only");
  let last_read = ref (OS.Clock.time ()) in
  let module M = struct
    let page_size_bytes = 4096
    let sector_size = 512
    let sectors_per_page = page_size_bytes / sector_size
    let read_sectors (start, length) =
      last_read := OS.Clock.time ();
      Int64.(blkif#read_512 (of_int start) (of_int length))
    let gettimeofday = OS.Clock.time
  end in
  let module Test = Perf.Test(M) in
  printf "starting in 3s\n%!";
  lwt () = OS.Time.sleep 3.0 in
  let watchdog_t =
    while_lwt true do
      lwt () = OS.Time.sleep 10.0 in
      let now = OS.Clock.time () in
      if now -. !last_read > 10.
      then printf "** more than 10s since last read request: deadlock?\n%!";
      OS.Activations.dump ();
      return ()
    done in
  lwt results = Test.go (Int64.to_int blkif#size) in

(* Write the results to the first page on the disk, unused for now:
  let results' = [
    "Sequential Read\n";
    "---------------\n";
  ] @ (List.map (fun (block_size, number) ->
    Printf.sprintf "%d, %.0f\n" block_size (float_of_int block_size *. number)
  ) results.Perf.seq_rd
  ) @ [
    "End"
  ] in

  lwt () = OS.Io_page.with_page
      (fun page ->
	let bs = OS.Io_page.to_bitstring page in
	let results = Bitstring.bitstring_of_string (String.concat "" results') in
	Bitstring.bitstring_write results 0 bs;
	blkif#write_page 0L bs
      ) in
*)
  lwt () = OS.Console.log_s "Random Read" in
  lwt () = OS.Console.log_s "-----------" in
  lwt () = OS.Console.log_s "# block size, MiB/sec" in
  lwt () = Lwt_list.iter_s
    (fun (block_size, p) ->
      OS.Console.log_s (sprintf "%d, %.1f, %s" block_size (Perf.Normal_population.mean p) (match Perf.Normal_population.sd p with Some x -> sprintf "%.1f" x | None -> "None"))
    ) results.Perf.rand_rd in
  return ()

