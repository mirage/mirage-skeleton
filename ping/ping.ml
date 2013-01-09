
let main () =
  Net.Manager.create (fun mgr iface id ->
    lwt () = Net.Manager.configure iface `DHCP in
    while_lwt true do
      print_endline "Blocked";
      OS.Time.sleep 3.0
    done
  )
let _ =
  OS.Main.run (main ())
