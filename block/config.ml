open Mirage

type shellconfig = ShellConfig
let shellconfig = Type ShellConfig

let config_shell = impl @@ object
    inherit base_configurable

    method configure i =
      let dir = Info.root i in
      Functoria_app.Cmd.run "dd if=/dev/zero of=%s/disk.img count=100000" dir

    method clean i =
      let dir = Info.root i in
      Functoria_app.Cmd.run "rm -f %s/disk.img" dir

    method module_name = "Functoria_runtime"
    method name = "shell_config"
    method ty = shellconfig
end


let main =
  let packages = [ "io-page" ; "duration" ] in
  let libraries = [ "io-page" ; "duration" ] in
  foreign
    ~libraries ~packages
    ~deps:[abstract config_shell] "Unikernel.Main" (block @-> job)

let img = block_of_file "disk.img"

let () =
  register "block_test" [main $ img]
