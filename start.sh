#!/bin/bash
export MIX_ENV=prod
echo "Starting application up..."
nohup mix run --no-halt &
echo $! > tmp/pid
