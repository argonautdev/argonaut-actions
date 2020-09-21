#!/bin/sh -l

echo "Entrypoint activated"
echo "Heave ho $1"
time=$(date)
echo "time in script is fucked: $time"
echo "::set-output name=time-now::$time"
# echo "::set-env name=time::$time"
