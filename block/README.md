This test assumes that a file `disk.img` exists to connect the block test to.

Generate it on Unix using the `generate_disk_img.sh` script.

On Xen, just attach a block device to the VM (but ensure that it's a scratch
disk, as it will be overwritten by this test).  Below is an example xl file
for Xen 4.2 (replace the file paths with your local versions):

```
name = 'block_test'
kernel = '/home/avsm/src/git/avsm/mirage-skeleton/block/mir-block_test.xen'
builder = 'linux'
memory = 256
disk = [ 'tap:aio:/home/avsm/src/git/avsm/mirage-skeleton/block/disk.img,xvda1,w']
```
