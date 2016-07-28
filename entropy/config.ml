open Mirage

let main =
  let libraries = [ "nocrypto" ; "hex" ] in
  let packages = [ "nocrypto" ; "hex" ] in
  foreign
    ~libraries ~packages
    ~deps:[abstract nocrypto]
    "Unikernel.Main" (console @-> job)

let () =
  register "entropy" [main $ default_console]
