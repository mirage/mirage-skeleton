#!/bin/sh

dd if=/dev/zero of=clear_littlefs bs=512K count=1
chamelon format clear_littlefs 512
ccmblock enc -i clear_littlefs -k 0x10786d3a9c920d0b3ec80dfaaac557a7 -o littlefs
