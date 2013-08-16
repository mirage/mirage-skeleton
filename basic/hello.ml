let main () =
  for_lwt i = 0 to 4 do
    OS.Console.log "hello" ;
    lwt () = OS.Time.sleep 2.0 in
    OS.Console.log "world" ;
    Lwt.return ()
  done
