#!/bin/sh -l

echo "Entrypoint activated"
echo "Hello $1"
time=$(date)
echo "::set-output name=time-now::$time"
# echo "::set-env name=time::$time"
