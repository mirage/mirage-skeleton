(* mirage >= 4.5.0 & < 4.8.0 *)
open Mirage

let setup = runtime_arg ~pos:__POS__ "Unikernel.setup"

let packages =
  [
    package ~min:"2.0" "pgx";
    package "pgx_lwt";
    package "pgx_lwt_mirage" ~min:"2.0";
    package "logs";
    package "mirage-logs";
    package ~max:"2.2.0" "conduit"
    (* force conduit-mirage and conduit to have the same version. *);
  ]

let stack = generic_stackv4 default_network

let server =
  main "Unikernel.Make" ~runtime_args:[ setup ] ~packages
    (random @-> time @-> pclock @-> mclock @-> stackv4 @-> job)

let () =
  register "pgx_unikernel"
    [
      server
      $ default_random
      $ default_time
      $ default_posix_clock
      $ default_monotonic_clock
      $ stack;
    ]
