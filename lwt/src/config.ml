open Mirage

let (name, main) =
  try match Sys.getenv "TARGET" with
      | "heads1" -> ("heads1", "Unikernels.Heads1")
      | "heads2" -> ("heads2", "Unikernels.Heads2")
      | "heads3" -> ("heads3", "Unikernels.Heads3")

      | "timeout1" -> ("timeout1", "Unikernels.Timeout1")
      | "timeout2" -> ("timeout2", "Unikernels.Timeout2")

      | "echo_server1" -> ("echo_server1", "Unikernels.Echo_server1")

  with Not_found -> failwith "Must specify target"

let () =
  let main = foreign main (console @-> job) in
  register name [ main $ default_console ]
