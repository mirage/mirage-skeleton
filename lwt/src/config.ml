open Mirage

let (name, main) =
  try match Sys.getenv "TARGET" with
      | "heads1" -> ("heads1", "Unikernels.Heads1")
      | "heads2" -> ("heads2", "Unikernels.Heads2")
      | "heads3" -> ("heads3", "Unikernels.Heads3")
  with Not_found -> ("heads1", "Unikernels.Heads1")

let () =
  let main = foreign main (console @-> job) in
  register name [ main $ default_console ]
