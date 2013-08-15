open Lwt
open OS

let one () =
  bind (join [
    bind (Time.sleep 1.0) (fun () ->
      print_endline "Heads"; return ()
    );
    bind (Time.sleep 2.0) (fun () ->
      print_endline "Tails"; return ()
    );
  ]) (fun () ->
    print_endline ("Finished"); return ()
  )
