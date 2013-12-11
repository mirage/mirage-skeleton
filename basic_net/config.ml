open Mirage

let () =
  Job.register [
    "Hello_net.Main", [Driver.console; Driver.tap0]
  ]
