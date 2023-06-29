open Lwt.Infix
open Cmdliner

let filename =
  let doc = Arg.info ~doc:"The filename to print out." [ "filename" ] in
  let key = Arg.(required & opt (some string) None doc) in
  Mirage_runtime.key key

module Make (Store : Mirage_kv.RO) = struct
  module Key = Mirage_kv.Key

  let start store =
    Store.get store (Key.v (filename ())) >|= function
    | Error err -> Logs.err (fun m -> m "Error: %a." Store.pp_error err)
    | Ok str -> Logs.info (fun m -> m "%s" str)
end
