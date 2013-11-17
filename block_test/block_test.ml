open Lwt
open Printf

let ( >>= ) x f = x >>= function
  | `Error _ -> fail (Failure "error")
  | `Ok x -> f x

let main _ =
  lwt () = Blkfront_init.register () in
  lwt module_b = OS.Block.find "local" in
  let module B = (val module_b: OS.Block.S) in
  B.connect "51712" >>= fun b ->
  lwt info = B.get_info b in
  printf "sectors = %Ld\nread_write=%b\nsector_size=%d\n%!"
    info.B.size_sectors info.B.read_write info.B.sector_size;
  OS.Time.sleep 5.
