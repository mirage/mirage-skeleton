open Mirage

let () =
  Job.register [
    "Mirage_guest_agent.Main", [Driver.console]
  ]
