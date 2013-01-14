open Datax
let mode =
  try match Sys.argv.(1) with
  | "memo" -> `memo
  | _      -> `none
  with _ -> `none

let ip =
  `IPv4 Net.Nettypes.(
    (ipv4_addr_of_tuple (10l,0l,0l,2l),
     ipv4_addr_of_tuple (255l,255l,255l,0l),
     [ipv4_addr_of_tuple (10l,0l,0l,1l)]
    ))

let _ = OS.Main.run (ServerDNS.main ~mode ~ip ())
