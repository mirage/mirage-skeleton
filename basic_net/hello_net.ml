open V1_LWT

module Main (C: CONSOLE) (N: NETWORK) = struct

  let start c n =
    for_lwt i = 0 to 4 do
      print_endline "hello" ;
      lwt () = OS.Time.sleep 2.0 in
      print_endline "world" ;
      Lwt.return ()
    done

end
