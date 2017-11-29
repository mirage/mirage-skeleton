open Mirage

let key =
  let doc = Key.Arg.info ~doc:"nsupdate key (ip:name:type:value)" ["key"] in
  Key.(create "key" Arg.(opt string "" doc))

let main = foreign ~deps:[abstract nocrypto] ~keys:Key.([ abstract key ])
    "Unikernel.Main"
    (console @-> network @-> pclock @-> mclock @-> time @-> random @-> job)

let () =
  let packages = [
    package ~min:"0.5" ~sublibs:["server"; "wire"] "charrua-core";
    package ~sublibs:["ethif"; "ipv4"; "udp"] "tcpip" ;
    package ~sublibs:["mirage"] "arp" ;
    package ~sublibs:["crypto"] "udns"
  ]
  in
  register "dhcp" ~packages [
    main $ default_console $ default_network $ default_posix_clock $ default_monotonic_clock $ default_time $ default_random
  ]
