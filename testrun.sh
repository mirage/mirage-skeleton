#!/bin/sh

$1/main.native &
sleep 1
kill $! 2> /dev/null
