module Main (C : Mirage_console.S) = struct
  let start c info =
    let { Mirage_runtime.name; libraries } = info in
    let s =
      Format.asprintf "name = %s@.libraries = %a@." name
        Fmt.(Dump.list @@ pair ~sep:(const char '.') string string)
        libraries
    in
    C.log c s
end
