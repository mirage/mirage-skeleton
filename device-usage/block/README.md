# Testing the block device interface

This example shows how to use block devices in MirageOS as well as some
common pitfalls. The test requires a disk image which can be generated with
e.g. `dd`:

    dd if=/dev/zero of=disk.img count=100000

You can build and launch the unikernel for unix like this:
```sh
$ mirage configure
$ make depends
$ make build
$ dd if=/dev/zero of=disk.img count=100000 # image can be reused
$ ./dist/block_test
```

You can build and run the unikernel for solo5 hvt like so:
```sh
$ mirage configure -t hvt
$ make depends
$ make build
$ dd if=/dev/zero of=disk.img count=100000 # image can be reused
$ solo5-hvt --block:storage=disk.img -- ./dist/block_test.hvt
```

For the solo5 spt target it is similar to the above. Just replace occurences of `hvt` with `spt`.
