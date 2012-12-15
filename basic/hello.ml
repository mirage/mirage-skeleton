let main () =
  print_endline "hello";
  lwt () = OS.Time.sleep 2.0 in
  print_endline "world";
  Lwt.return ()

let _ =
  OS.Main.run (main ())
