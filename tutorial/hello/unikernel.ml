module Hello (_ : sig end) = struct
  let start __ =
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
          Logs.info (fun f -> f "hello");
          loop (n - 1)
          (* Time.sleep_ns (Duration.of_sec 1) >>= fun () -> loop (n - 1) *)
    in
    loop 4
end
