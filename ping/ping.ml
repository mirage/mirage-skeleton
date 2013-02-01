let main () =
  Printf.printf "Running\n%!";
  while_lwt true do
    print_endline "Blocked";
    OS.Time.sleep 3.0
  done
