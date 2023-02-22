open Mirage

let unikernel = foreign "Unikernel.Make"
    ~packages:[
      package "hxd" ~sublibs:[ "core"; "string" ];
      package ~build:true ~max:"3.7.0" "dune";
    ]
  (random @-> console @-> kv_rw @-> job)

let aes_ccm_key =
  let doc = Key.Arg.info [ "aes-ccm-key" ] ~doc:"The key of the block device (hex formatted)" in
  Key.(create "aes-ccm-key" Arg.(required string doc))

let program_block_size =
  let doc = Key.Arg.info [ "program-block-size" ] in
  Key.(create "program_block_size" Arg.(opt int 16 doc))

let block = block_of_file "littlefs"
let encrypted_block = ccm_block aes_ccm_key block
let fs = chamelon ~program_block_size encrypted_block

let () = register "elittlefs"
  [ unikernel $ default_random $ default_console $ fs ]
