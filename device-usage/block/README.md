# Testing the block device interface

This example shows how to use block devices in MirageOS as well as some
common pitfalls. The test requires a disk image which can be generated with
e.g. `dd`:

    dd if=/dev/zero of=disk.img count=100000

You can build and launch the unikernel like this:
```sh
$ mirage configure
$ make depends
$ make build
$ dd if=/dev/zero of=disk.img count=100000 # image can be reused
$ ./dist/block_test
```
