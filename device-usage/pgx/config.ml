open Mirage

let packages =
  [ package ~min:"2.0" "pgx"
  ; package "pgx_lwt"
  ; package "pgx_lwt_mirage" ~min:"2.0"
  ; package "logs"
  ; package "mirage-logs"
  ; package ~max:"2.2.0" "conduit" (* force conduit-mirage and conduit to have the same version. *)
  ]
;;

let stack = generic_stackv4 default_network

let database =
  let doc = Key.Arg.info ~doc:"database to use" [ "db"; "pgdatabase" ] in
  Key.(create "pgdatabase" Arg.(opt string "postgres" doc))
;;

let port =
  let doc = Key.Arg.info ~doc:"port to use for postgresql" [ "p"; "pgport" ] in
  Key.(create "pgport" Arg.(opt int 5432 doc))
;;

let hostname =
  let doc = Key.Arg.info ~doc:"host for postgres database" [ "h"; "pghost" ] in
  Key.(create "pghost" Arg.(required string doc))
;;

let user =
  let doc = Key.Arg.info ~doc:"postgres user" [ "u"; "pguser" ] in
  Key.(create "pguser" Arg.(required string doc))
;;

let password =
  let doc = Key.Arg.info ~doc:"postgres password" [ "pgpassword" ] in
  Key.(create "pgpassword" Arg.(required string doc))
;;

let server =
  main
    "Unikernel.Make"
    ~keys:
      [ key port
      ; key hostname
      ; key user
      ; key password
      ; key database
      ]
    ~packages
    (random @-> time @-> pclock @-> mclock @-> stackv4 @-> job)
;;

let () =
  register
    "pgx_unikernel"
    [ server $ default_random $ default_time $ default_posix_clock $ default_monotonic_clock $ stack ]
;;
