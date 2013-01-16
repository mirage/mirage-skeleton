#!/bin/sh -e

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  ping -c 100000 -q -f $1 > pinglog-$i.txt &
done
wait
cat pinglog-*.txt
