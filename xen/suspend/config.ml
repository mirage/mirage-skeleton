open Mirage

let main = foreign "Mirage_guest_agent.Main" (console @-> job)

let () =
  register "suspend" [
    main $ default_console
  ]
