open Mirage

let () =
  Job.register [
    "Hello.Main", [Driver.console]
  ]
