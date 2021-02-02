open Mirage

let main packages =
  foreign "Unikernel.Main" ~packages
    (console @-> network @-> mclock @-> time @-> job)

(* [charrua] needs [caml_tcpip_ones_complement_checksum],
   which is provided by [tcpip.unix] on unix and by the
   [mirage-solo5] for the other targets (and which is
   automatically added by the mirage tool in that case). *)
let main =
  match_impl Key.(value target)
    [`Unix, main [package "tcpip" ~sublibs:["unix"]]]
     ~default:(main [])

let () =
  let packages = [
    package ~min:"1.0.0" "charrua";
    package "charrua-server";
    package ~min:"2.3.0" ~sublibs:["mirage"] "arp";
    package "ethernet"
  ]
  in
  register "dhcp" ~packages [
      main
      $ default_console
      $ default_network
      $ default_monotonic_clock
      $ default_time
  ]
