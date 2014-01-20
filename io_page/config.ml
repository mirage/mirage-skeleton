open Mirage

let () =
  register "iopage" [
    foreign "Iop.Main" (console @-> job) $ default_console
  ]
