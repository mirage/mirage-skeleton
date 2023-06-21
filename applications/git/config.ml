open Mirage

type hash = Hash

let hash = typ Hash
let sha1 = impl ~packages:[ package "digestif" ] "Digestif.SHA1" hash

type git = Git

let git = typ Git

let git_impl path =
  let packages = [ package "git" ~min:"3.8.0" ] in
  let keys = match path with None -> [] | Some path -> [ Key.v path ] in
  let connect _ modname _ =
    match path with
    | None ->
        Fmt.str
          {ocaml|%s.v (Fpath.v ".") >>= function
                 | Ok v -> Lwt.return v
                 | Error err -> Fmt.failwith "%%a" %s.pp_error err|ocaml}
          modname modname
    | Some key ->
        Fmt.str
          {ocaml|( match Option.map Fpath.of_string %a with
                 | Some (Ok path) -> %s.v path
                 | Some (Error (`Msg err)) -> failwith err
                 | None -> %s.v (Fpath.v ".") ) >>= function
                 | Ok v -> Lwt.return v
                 | Error err -> Fmt.failwith "%%a" %s.pp_error err|ocaml}
          Key.serialize_call (Key.v key) modname modname modname
  in
  impl ~packages ~keys ~connect "Git.Mem.Make" (hash @-> git)

(* User space *)

let remote =
  let doc = Key.Arg.info ~doc:"Remote Git repository." [ "r"; "remote" ] in
  Key.(create "remote" Arg.(required string doc))

let ssh_key =
  let doc = Key.Arg.info ~doc:"The private SSH key." [ "ssh-key" ] in
  Key.(create "ssh_seed" Arg.(opt (some string) None doc))

let ssh_password =
  let doc = Key.Arg.info ~doc:"The private SSH password." [ "ssh-password" ] in
  Key.(create "ssh_password" Arg.(opt (some string) None doc))

let nameservers =
  let doc = Key.Arg.info ~doc:"DNS nameservers." [ "nameserver" ] in
  Key.(create "nameservers" Arg.(opt_all string doc))

let ssh_authenticator =
  let doc =
    Key.Arg.info ~doc:"SSH public key of the remote Git repository."
      [ "ssh-authenticator" ]
  in
  Key.(create "ssh_authenticator" Arg.(opt (some string) None doc))

let https_authenticator =
  let doc =
    Key.Arg.info ~doc:"SSH public key of the remote Git repository."
      [ "https-authenticator" ]
  in
  Key.(create "https_authenticator" Arg.(opt (some string) None doc))

let branch =
  let doc = Key.Arg.info ~doc:"The Git remote branch." [ "branch" ] in
  Key.(create "branch" Arg.(opt string "refs/heads/master" doc))

let minigit =
  foreign "Unikernel.Make"
    ~packages:[ package "ptime" ]
    ~keys:[ Key.v remote; Key.v branch ]
    (git @-> git_client @-> job)

let mimic stackv4v6 dns_client happy_eyeballs =
  let tcpv4v6 = tcpv4v6_of_stackv4v6 stackv4v6 in
  let mhappy_eyeballs =
    mimic_happy_eyeballs stackv4v6 dns_client happy_eyeballs
  in
  let mtcp = git_tcp tcpv4v6 mhappy_eyeballs in
  let mssh =
    git_ssh ~authenticator:ssh_authenticator ~key:ssh_key ~password:ssh_password
      tcpv4v6 mhappy_eyeballs
  in
  let mhttp =
    git_http ~authenticator:https_authenticator tcpv4v6 mhappy_eyeballs
  in
  merge_git_clients mhttp (merge_git_clients mtcp mssh)

let stackv4v6 = generic_stackv4v6 default_network
let mclock = default_monotonic_clock
let pclock = default_posix_clock
let time = default_time
let random = default_random
let dns_client = generic_dns_client ~nameservers stackv4v6
let happy_eyeballs = generic_happy_eyeballs stackv4v6 dns_client
let git = git_impl None $ sha1
let mimic = mimic stackv4v6 dns_client happy_eyeballs

let () =
  register "minigit" [ minigit $ git $ mimic ]
