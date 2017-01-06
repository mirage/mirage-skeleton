#!/bin/sh

set -x

# run the target in the background, capturing its PID
$1/main.native &
pid=$!

# sleep for a second to give the target a chance to start, and kill it
sleep 1
kill $pid

# capture the exit status of the target
wait $pid
es=$?

# exit with the target's exit status, declaring success if the target was
# running long enough that it needed to be killed -- the exit status of `wait
# $pid` is either that of $pid or 128+N if $pid was terminated via signal N
if [ $es = 143 ] ; then
    exit 0
else
    exit $es
fi
