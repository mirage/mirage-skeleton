open Cmdliner

let ssh_key =
  let doc = Arg.info ~doc:"The private SSH key." [ "ssh-key" ] in
  Arg.(value & opt (some string) None doc)

let ssh_password =
  let doc = Arg.info ~doc:"The private SSH password." [ "ssh-password" ] in
  Arg.(value & opt (some string) None doc)

let nameservers =
  let doc = Arg.info ~doc:"DNS nameservers." [ "nameserver" ] in
  Arg.(value & opt_all string [] doc)

let ssh_authenticator =
  let doc =
    Arg.info ~doc:"SSH public key of the remote Git repository."
      [ "ssh-authenticator" ]
  in
  Arg.(value & opt (some string) None doc)

let https_authenticator =
  let doc =
    Arg.info ~doc:"SSH public key of the remote Git repository."
      [ "https-authenticator" ]
  in
  Arg.(value & opt (some string) None doc)
