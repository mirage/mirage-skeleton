open Lwt

module Main (C: V1_LWT.CONSOLE) = struct

(*  let sources () =
    (* some conditional compilation stuff here, Nocrypto_entropy_mirage is only
       available on Xen and Solo5, but Nocrypto_entropy_unix.sys_rng may be of interest *) 
    let tostr = function
      | `Timer -> "timer"
      | `Rdseed -> "rdseed"
      | `Rdrand -> "rdrand"
      | `Xentropyd -> "xentropyd"
    in
    match Nocrypto_entropy_mirage.sources () with
    | Some xs -> C.log_s c ("sources: " ^ String.concat ", " (List.map tostr xs))
    | None -> C.log_s c "no sources" *)
  
  let start c _ =
    (* sources () >>= fun () -> *)
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n ->
        let rand = Nocrypto.Rng.generate 16 in
        let str = Hex.hexdump_s ~print_chars:false (Hex.of_cstruct rand) in
        C.log_s c str >>= fun () ->
        OS.Time.sleep 0.1 >>= fun () ->
        loop (n - 1)
    in
    loop 10
end
