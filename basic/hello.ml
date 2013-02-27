let main _ _ _ =
  for_lwt i = 0 to 10 do
    print_endline "hello";
    lwt () = OS.Time.sleep 2.0 in
    print_endline "world";
    Lwt.return ()
  done
