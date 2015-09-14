open Mirage

(* Use `FS` to set the underlying filesystem:
   FS=crunch (or nothing): use static filesystem via crunch
   FS=fat: use FAT and block device (run ./make-fat-images.sh)
 *)
let mode =
  try match String.lowercase (Unix.getenv "FS") with
    | "fat"     -> `Fat
    | "archive" -> `Archive
    | _         -> `Crunch
  with Not_found ->
    `Crunch

let fat_ro dir =
  kv_ro_of_fs (fat_of_files ~dir ())

let fs = match mode with
  | `Fat    -> fat_ro "./htdocs"
  | `Crunch -> crunch "./htdocs"
  | `Archive -> archive_of_files ~dir:"./htdocs" ()

let stack = generic_stackv4 default_console tap0

let http_srv = http_server (conduit_direct ~tls:true stack)

let main =
  let libraries = ["re.str"; "magic-mime"] in
  let packages = ["re"; "magic-mime"] in
  foreign
    ~libraries ~packages
    "Dispatch.Main" (console @-> kv_ro @-> http @-> job)

let () =
  register "www" [
    main $ default_console $ fs $ http_srv
  ]
