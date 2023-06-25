open Mirage

type shellconfig = ShellConfig

let shellconfig = typ ShellConfig

let config_shell =
  impl
    ~dune:(fun _ ->
      [
        Dune.stanza
          {|
(rule (targets disk.img)
 (action (run dd if=/dev/zero of=disk.img count=100000))
)|};
      ])
    ~install:(fun _ -> Functoria.Install.v ~etc:[ Fpath.v "disk.img" ] ())
    "shell_config" shellconfig

let main =
  let packages =
    [
      package "io-page";
      package "duration";
      package ~build:true "bos";
      package ~build:true "fpath";
    ]
  in
  main ~packages
    ~extra_deps:[ dep config_shell ]
    "Unikernel.Main"
    (time @-> block @-> job)

let img =
  Key.(if_impl is_solo5 (block_of_file "storage") (block_of_file "disk.img"))

let () = register "block_test" [ main $ default_time $ img ]
