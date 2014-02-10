open Lwt

module Main (C: V1_LWT.CONSOLE) = struct

  let start c =
    for_lwt i = 0 to 4 do
      C.log c "hello" ;
      lwt () = OS.Time.sleep 1.0 in
      C.log c "world" ;
      return ()
    done

end
