open Mirage

type mimic = Mimic

let mimic = typ Mimic

let mimic_count =
  let v = ref (-1) in
  fun () ->
    incr v;
    !v

let mimic_conf () =
  let packages = [ package "mimic" ] in
  let connect _ _modname = function
    | [ a; b ] -> Fmt.str "Lwt.return (Mimic.merge %s %s)" a b
    | [ x ] -> Fmt.str "%s.ctx" x
    | _ -> Fmt.str "Lwt.return Mimic.empty"
  in
  impl ~packages ~connect "Mimic.Merge" (mimic @-> mimic @-> mimic)

let merge ctx0 ctx1 = mimic_conf () $ ctx0 $ ctx1

let mimic_tcp_conf =
  let packages = [ package "git-mirage" ~max:"3.7.0" ~sublibs:[ "tcp" ] ] in
  let connect _ modname = function
    | [ stack ] ->
        Fmt.str {ocaml|Lwt.return (%s.with_stack %s %s.ctx)|ocaml} modname stack
          modname
    | _ -> assert false
  in
  impl ~packages ~connect "Git_mirage_tcp.Make" (stackv4v6 @-> mimic)

let mimic_tcp_impl stackv4v6 = mimic_tcp_conf $ stackv4v6

let mimic_ssh_conf ~kind ~seed ~auth =
  let seed = Key.v seed in
  let auth = Key.v auth in
  let keys = [ seed; auth ] in
  let packages = [ package "git-mirage" ~max:"3.7.0" ~sublibs:[ "ssh" ] ] in
  let connect _ modname = function
    | [ _; tcp_ctx; _ ] ->
        let with_key =
          match kind with
          | `Rsa -> "with_rsa_key"
          | `Ed25519 -> "with_ed25519_key"
        in
        Fmt.str
          {ocaml|let ssh_ctx00 = Mimic.merge %s %s.ctx in
                 let ssh_ctx01 = Option.fold ~none:ssh_ctx00 ~some:(fun v -> %s.%s v ssh_ctx00) %a in
                 let ssh_ctx02 = Option.fold ~none:ssh_ctx01 ~some:(fun v -> %s.with_authenticator v ssh_ctx01) %a in
                 Lwt.return ssh_ctx02|ocaml}
          tcp_ctx modname modname with_key Key.serialize_call seed modname
          Key.serialize_call auth
    | _ -> assert false
  in
  impl ~keys ~packages ~connect "Git_mirage_ssh.Make"
    (stackv4v6 @-> mimic @-> mclock @-> mimic)

let mimic_ssh_impl ~kind ~seed ~auth stackv4v6 mimic_git mclock =
  mimic_ssh_conf ~kind ~seed ~auth $ stackv4v6 $ mimic_git $ mclock

(* TODO(dinosaure): user-defined nameserver and port. *)

let mimic_dns_conf =
  let packages = [ package "git-mirage" ~min:"3.6.0" ~max:"3.7.0" ~sublibs:[ "dns" ] ] in
  let connect _ modname = function
    | [ _; _; _; _; stack; tcp_ctx ] ->
        Fmt.str
          {ocaml|let dns_ctx00 = Mimic.merge %s %s.ctx in
                 let dns_ctx01 = %s.with_dns %s dns_ctx00 in
                 Lwt.return dns_ctx01|ocaml}
          tcp_ctx modname modname stack
    | _ -> assert false
  in
  impl ~packages ~connect "Git_mirage_dns.Make"
    (random @-> mclock @-> pclock @-> time @-> stackv4v6 @-> mimic @-> mimic)

let mimic_dns_impl random mclock pclock time stackv4v6 mimic_tcp =
  mimic_dns_conf $ random $ mclock $ pclock $ time $ stackv4v6 $ mimic_tcp

type hash = Hash

let hash = typ Hash

let sha1 =
  let packages = [ package "digestif" ] in
  impl ~packages "Digestif.SHA1" hash

type git = Git

let git = typ Git

let git_conf ?path () =
  let keys = match path with Some path -> [ Key.v path ] | None -> [] in
  let packages = [ package ~min:"3.3.2" "git"; package "digestif" ] in
  let connect _ modname _ =
    match path with
    | None ->
        Fmt.str
          {|%s.v (Fpath.v ".") >>= function
            | Ok v -> Lwt.return v
            | Error err -> Fmt.failwith "%%a" %s.pp_error err|}
          modname modname
    | Some key ->
        Fmt.str
          {|let res = match Option.map Fpath.of_string %a with
               | Some (Ok path) -> %s.v path
               | Some (Error (`Msg err)) -> failwith err
               | None -> %s.v (Fpath.v ".") in
             res >>= function
             | Ok v -> Lwt.return v
             | Error err -> Fmt.failwith "%%a" %s.pp_error err|}
          Key.serialize_call (Key.v key) modname modname modname
  in
  impl ~keys ~packages ~connect "Git.Mem.Make" (hash @-> git)

let git_impl ?path hash = git_conf ?path () $ hash

let mimic_paf_conf () =
  let packages = [ package "git-paf" ] in
  let connect _ modname = function
    | [ _; _; _; tcp_ctx ] ->
        Fmt.str
          {ocaml|let paf_ctx00 = Mimic.merge %s %s.ctx in
                 Lwt.return paf_ctx00|ocaml}
          tcp_ctx modname
    | _ -> assert false
  in
  impl ~packages ~connect "Git_paf.Make"
    (time @-> pclock @-> stackv4v6 @-> mimic @-> mimic)

let mimic_paf_impl time pclock stackv4v6 mimic_tcp =
  mimic_paf_conf () $ time $ pclock $ stackv4v6 $ mimic_tcp

(* User space *)

let remote =
  let doc = Key.Arg.info ~doc:"Remote Git repository." [ "r"; "remote" ] in
  Key.(create "remote" Arg.(required string doc))

let ssh_seed =
  let doc = Key.Arg.info ~doc:"Seed of the private SSH key." [ "ssh-seed" ] in
  Key.(create "ssh_seed" Arg.(opt (some string) None doc))

let ssh_auth =
  let doc =
    Key.Arg.info ~doc:"SSH public key of the remote Git endpoint."
      [ "ssh-auth" ]
  in
  Key.(create "ssh_auth" Arg.(opt (some string) None doc))

let minigit =
  foreign "Unikernel.Make"
    ~keys:[ Key.v remote; Key.v ssh_seed; Key.v ssh_auth ]
    (git @-> mimic @-> job)

let mimic ~kind ~seed ~auth stackv4v6 random pclock mclock time =
  let mtcp = mimic_tcp_impl stackv4v6 in
  let mdns = mimic_dns_impl random mclock pclock time stackv4v6 mtcp in
  let mssh = mimic_ssh_impl ~kind ~seed ~auth stackv4v6 mtcp mclock in
  let mpaf = mimic_paf_impl time pclock stackv4v6 mtcp in
  merge mpaf (merge mssh mdns)

let stackv4v6 = generic_stackv4v6 default_network
let mclock = default_monotonic_clock
let pclock = default_posix_clock
let time = default_time
let random = default_random
let git = git_impl sha1
let mimic = mimic ~kind:`Rsa ~seed:ssh_seed ~auth:ssh_auth
let mimic = mimic stackv4v6 random pclock mclock time

let () =
  register "minigit"
    ~packages:[ package "ptime"; package "git-paf" ]
    [ minigit $ git $ mimic ]
