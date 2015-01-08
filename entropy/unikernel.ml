open Lwt

module Main (C: V1_LWT.CONSOLE)(E: V1_LWT.ENTROPY) = struct

  let start c e =
    E.handler e (fun ~source data ->
      Printf.printf "Entropy source=%d; data = %s\n%!" source (String.escaped (Cstruct.to_string data))
    ) >>= fun () ->
    for_lwt i = 0 to 4 do
      C.log c "hello" ;
      lwt () = OS.Time.sleep 1.0 in
      C.log c "world" ;
      return ()
    done

end
