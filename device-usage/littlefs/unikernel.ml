open Lwt.Infix

let identity x = x

module Make (Random : Mirage_random.S) (Store : Mirage_kv.RW) = struct
  let key = Mirage_kv.Key.v

  let start _random store =
    Store.set store (key "/foo") "Hello World!"
    >|= Result.map_error (Fmt.str "%a" Store.pp_write_error)
    >|= Result.fold ~ok:identity ~error:failwith
    >>= fun () ->
    Store.get store (key "/foo")
    >|= Result.map_error (Fmt.str "%a" Store.pp_error)
    >|= Result.fold ~ok:identity ~error:failwith
    >|= fun str ->
    Logs.info (fun m -> m "foo: @[<hov>%a@]" (Hxd_string.pp Hxd.default) str)
end
