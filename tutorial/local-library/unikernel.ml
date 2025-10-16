let start () =
  Logs.info (fun f ->
      f "The hello library has a message for you: %s" Hello.hello);
  Lwt.return_unit
