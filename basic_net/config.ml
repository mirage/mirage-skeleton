open Mirage

let () =
  let main =
    foreign "Hello_net.Main"
      (console @-> network @-> job) 
  in
  register "basic_net" [ main $ default_console $ tap0 ]
