open Lwt.Infix

module Make
    (RANDOM : Mirage_random.S)
    (PCLOCK : Mirage_clock.PCLOCK)
    (MCLOCK : Mirage_clock.MCLOCK)
    (STACK : Mirage_stack.V4) =
struct
  module Pgx_mirage = Pgx_lwt_mirage.Make (RANDOM) (MCLOCK) (STACK)
  module Logs_reporter = Mirage_logs.Make (PCLOCK)

  type user =
    { id : int
    ; email : string
    }

  let data = [ "foo@test.com"; "bar@foo.com"; "hello@test.net"; "bar@baz.test" ]

  let setup_database ~port ~user ~host ~password ~database pgx () =
    Logs.info (fun m -> m "setting up database");
    let module P = (val pgx : Pgx_lwt.S) in
    P.with_conn ~user ~host ~password ~port ~database (fun conn ->
        P.execute_unit
          conn
          "CREATE TABLE IF NOT EXISTS users( id SERIAL PRIMARY KEY, email VARCHAR(40) \
           NOT NULL UNIQUE );"
        >>= fun () ->
        let params = List.map (fun email -> Pgx.Value.[ of_string email ]) data in
        P.execute_many
          conn
          ~params
          ~query:"INSERT INTO USERS (email) VALUES ($1) ON CONFLICT (email) DO NOTHING"
        >>= fun rows ->
        Logs.info (fun m -> m "Inserted %d rows" (List.length rows));
        Lwt.return_unit)
  ;;

  let get_users ~port ~user ~host ~password ~database pgx () =
    Logs.info (fun m -> m "Fetching users");
    let module P = (val pgx : Pgx_lwt.S) in
    P.with_conn ~user ~host ~password ~port ~database (fun conn ->
        P.execute_map ~params:[] conn "SELECT * FROM USERS" ~f:(fun row ->
          match row with
          | [ id; email ] ->
              Lwt.return { id = Pgx.Value.to_int_exn id; email = Pgx.Value.to_string_exn email }
          | _ -> failwith "Invalid data"))
  ;;

  let print_users users =
    users
    >|= fun users ->
    List.iter
      (fun { id; email } -> Logs.info (fun m -> m "{id = %d; email = %s}\n" id email))
      users
  ;;

  let start _random _pclock _mclock stack =
    Logs.(set_level (Some Info));
    Logs_reporter.(create () |> run)
    @@ fun () ->
    let port = Key_gen.pgport () in
    let host = Key_gen.pghost () in
    let user = Key_gen.pguser () in
    let password = Key_gen.pgpassword () in
    let database = Key_gen.pgdatabase () in
    let pgx = Pgx_mirage.connect stack in
    setup_database ~port ~host ~user ~password ~database pgx ()
    >>= fun () -> print_users (get_users ~port ~host ~user ~password ~database pgx ())
  ;;
end
