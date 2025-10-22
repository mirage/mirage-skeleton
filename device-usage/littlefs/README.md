# A simple example of a read-write file-system

This is an example of a MirageOS with a cleartext file-system.
You can craft an image with `./create_image.sh` which requires:
- `chamelon-unix`
- the `dd` command

You can build and launch the unikernel like this:
```sh
$ mirage configure
$ make depends
$ mirage build
$ opam install chamelon-unix
$ ./create_image.sh
$ ./dist/elittlefs 
```
