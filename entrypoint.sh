#!/bin/sh -l


NAME=$1
CWD=$2
echo "Entrypoint activated"
echo "Heave ho $1"
chmod +x $2/goodbye.sh
time=$(date)
echo "::set-output name=time-now::$time"
sh goodbye.sh