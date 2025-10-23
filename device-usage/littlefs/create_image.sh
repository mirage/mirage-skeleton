#!/bin/sh

dd if=/dev/zero of=littlefs bs=512K count=1
# if you're missing `chamelon`, try `opam install chamelon-unix`
chamelon format littlefs 512
