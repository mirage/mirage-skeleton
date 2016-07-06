open Mirage

let handler = foreign "Unikernel.Main" (console @-> stackv4 @-> job)

let stack = generic_stackv4 tap0

let () =
  register "stackv4" [handler $ default_console $ stack]
