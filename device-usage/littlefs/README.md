# A simple example of an encrypted file-system

This is an example of a MirageOS with an encrypted file-system.
You can craft an image with `./create_image.sh` which requires:
- `chamelon-unix`
- `mirage-block-ccm`
- the `dd` command

The file-system is encrypted with the key `0x10786d3a9c920d0b3ec80dfaaac557a7`.
You can build and launch the unikernel like this:
```sh
$ mirage configure
$ make depends
$ mirage build
$ opam install chamelon-unix mirage-block-ccm
$ ./create_image.sh
$ ./dist/elittlefs --aes-ccm-key 0x10786d3a9c920d0b3ec80dfaaac557a7
```
