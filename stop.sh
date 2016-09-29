#!/bin/bash
PID=`cat tmp/pid`
echo "Stopping app running with $PID"
kill $PID
rm tmp/pid

