This test assumes that a file `disk.img` exists to connect the block test to.
Generate it on Unix using the `generate_disk_img.sh` script.

On Unix:
```
mirage configure
make
./mir-block_test
```

On Xen:
```
mirage configure -t xen
make
sudo xl create -c block_test.xl
```

