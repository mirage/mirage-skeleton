open Mirage

let mode =
  let x = try Unix.getenv "FS" with Not_found -> "crunch" in
  match x with
  | "fat" -> `Fat
  | "crunch" -> `Crunch
  | x -> failwith ("Unknown FS mode: " ^ x )

let fat_ro dir =
  kv_ro_of_fs (fat_of_files ~dir ())

let disk =
  match mode, get_mode () with
  | `Fat   , _     -> fat_ro "t"
  | `Crunch, `Xen  -> crunch "t"
  | `Crunch, `Unix -> direct_kv_ro "t"

let main =
  foreign "Unikernel.Main" (console @-> kv_ro @-> kv_ro @-> job)

let () =
  register "kv_ro" [ main $ default_console $ disk $ disk ]
