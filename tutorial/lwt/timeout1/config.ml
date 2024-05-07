(* mirage >= 4.4.0 & < 4.6.0 *)
open Mirage

let main =
  let extra_deps = [ dep default_time ] in
  main
    ~extra_deps
    ~packages:[ package "duration"; package ~max:"0.2.0" "randomconv" ]
    "Unikernel.Timeout1"
    (random @-> job)

let () = register "timeout1" [ main $ default_random ]
