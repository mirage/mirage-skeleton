open Lwt.Infix

module Make (Store : Mirage_kv.RO) = struct
  module Key = Mirage_kv.Key

  let start store =
    Store.get store (Key.v (Key_gen.filename ())) >|= function
    | Error err -> Logs.err (fun m -> m "Error: %a." Store.pp_error err)
    | Ok str -> Logs.info (fun m -> m "%s" str)
end
