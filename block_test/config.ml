open Mirage

let block = {
  Block.name = "myfile";
  filename   = "./disk.raw";
  read_only  = false;
}

let () = Job.register [
    "Block_test.Main", [Driver.console; Driver.Block block]
  ]
