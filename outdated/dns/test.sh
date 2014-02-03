#!/bin/sh

./queryperf -q 10 -l 10 -s $1  < lib_test/queryperf-100.txt
