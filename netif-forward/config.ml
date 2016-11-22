open Mirage

let main = foreign "Unikernel.Main" (console @-> network @-> network @-> job)

let () =
  register "network" ~packages:[package "rresult"]
    [ main $ default_console $ (netif "1") $ (netif ~group:"other" "2") ]
