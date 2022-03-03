open Lwt.Infix

module Make (Console : Mirage_console.S) (Store : Mirage_kv.RO) = struct
  module Key = Mirage_kv.Key

  let log console fmt = Fmt.kstr (Console.log console) fmt

  let start console store =
    Store.get store (Key.v (Key_gen.filename ())) >>= function
    | Error err -> log console "Error: %a.\n%!" Store.pp_error err
    | Ok str -> Console.write console (Cstruct.of_string str) >>= function
      | Ok () -> Lwt.return_unit
      | Error err -> log console "Error: %a.\n%!" Console.pp_write_error err
end
