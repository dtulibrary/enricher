#!/bin/bash
count=`grep -E -o rows=[0-9]* log/debug.log | sed 's/rows=//g' | paste -s -d "+" | bc`
start=`head -1 log/debug.log | awk '{print $1}'`
commits=`grep --count "committing updates" log/debug.log` 
printf "%'d since $start with $commits commits.\n" $count 
