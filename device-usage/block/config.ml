open Mirage

type shellconfig = ShellConfig
let shellconfig = Type ShellConfig

let config_shell = impl @@ object
    inherit base_configurable

    method build _i =
      Bos.OS.Cmd.run Bos.Cmd.(v "dd" % "if=/dev/zero" % "of=disk.img" % "count=100000")

    method clean _i =
      Bos.OS.File.delete (Fpath.v "disk.img")

    method module_name = "Functoria_runtime"
    method name = "shell_config"
    method ty = shellconfig
end


let main =
  let packages = [ package "io-page"; package "duration"; package ~build:true "bos"; package ~build:true "fpath" ] in
  foreign
    ~packages
    ~deps:[abstract config_shell] "Unikernel.Main" (time @-> block @-> job)

let img = block_of_file "disk.img"

let () =
  register "block_test" [main $ default_time $ img]
