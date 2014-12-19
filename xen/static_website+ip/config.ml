open Mirage

(* If the Unix `MODE` is set, the choice of configuration changes:
   MODE=crunch (or nothing): use static filesystem via crunch
   MODE=fat: use FAT and block device (run ./make-fat-images.sh)
 *)
let mode =
  try match String.lowercase (Unix.getenv "FS") with
    | "fat" -> `Fat
    | _     -> `Crunch
  with Not_found ->
    `Crunch

let fat_ro dir =
  kv_ro_of_fs (fat_of_files ~dir ())

let fs = match mode with
  | `Fat    -> fat_ro "./htdocs"
  | `Crunch -> crunch "./htdocs"

let main =
  foreign "Dispatch.Main" (console @-> kv_ro @-> network @-> job)

let () =
  add_to_ocamlfind_libraries ["mirage-http";"tcpip.ethif"; "tcpip.tcp"; "tcpip.udp"; "tcpip.dhcpv4" ];
  add_to_opam_packages ["mirage-http"];
  register "www" [
    main $ default_console $ fs $ tap0
  ]
