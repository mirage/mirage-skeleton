open Lwt.Infix

let identity x = x

let program_block_size =
  let open Cmdliner in
  let doc =
    Arg.info ~doc:"program block size for chamelon" [ "program-block-size" ]
  in
  Arg.(value & opt int 16 doc)

module Make (Store : Mirage_kv.RW) = struct
  let key = Mirage_kv.Key.v

  let start store =
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
