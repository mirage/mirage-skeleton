open Mirage

type hash = Hash

let hash = typ Hash
let sha1 = impl ~packages:[ package "digestif" ] "Digestif.SHA1" hash

type git = Git

let git = typ Git

let git_impl path =
  let packages = [ package "git" ~min:"3.8.0" ] in
  let runtime_args =
    match path with None -> [] | Some path -> [ Runtime_arg.v path ]
  in
  let connect _ modname _ =
    match path with
    | None ->
        code ~pos:__POS__
          {ocaml|%s.v (Fpath.v ".") >>= function
                 | Ok v -> Lwt.return v
                 | Error err -> Fmt.failwith "%%a" %s.pp_error err|ocaml}
          modname modname
    | Some key ->
        code ~pos:__POS__
          {ocaml|( match Option.map Fpath.of_string %a with
                 | Some (Ok path) -> %s.v path
                 | Some (Error (`Msg err)) -> failwith err
                 | None -> %s.v (Fpath.v ".") ) >>= function
                 | Ok v -> Lwt.return v
                 | Error err -> Fmt.failwith "%%a" %s.pp_error err|ocaml}
          Runtime_arg.call key modname modname modname
  in
  impl ~packages ~runtime_args ~connect "Git.Mem.Make" (hash @-> git)

(* User space *)

let ssh_key = Runtime_arg.create "Key.ssh_key"
let ssh_password = Runtime_arg.create "Key.ssh_password"
let nameservers = Runtime_arg.create "Key.nameservers"
let ssh_authenticator = Runtime_arg.create "Key.ssh_authenticator"
let https_authenticator = Runtime_arg.create "Key.https_authenticator"

let minigit =
  main "Unikernel.Make"
    ~packages:[ package "ptime" ]
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
let () = register "minigit" [ minigit $ git $ mimic ]
