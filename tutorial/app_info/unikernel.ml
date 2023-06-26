module Main (_ : sig end) = struct
  let start () info =
    let { Mirage_runtime.name; libraries } = info in
    Logs.info (fun m ->
        m "name = %s@.libraries = %a@." name
          Fmt.(Dump.list @@ pair ~sep:(const char '.') string string)
          libraries);
    Lwt.return_unit
end
