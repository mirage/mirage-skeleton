open Mirage_types.V1

module Main (C: CONSOLE) = struct

  let start c =
    for_lwt i = 0 to 4 do
      C.log c "hello" ;
      lwt () = OS.Time.sleep 2.0 in
      C.log c "world" ;
      Lwt.return ()
    done

end
