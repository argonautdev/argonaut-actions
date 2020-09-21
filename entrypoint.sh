#!/bin/sh -l


NAME=$1
CWD=`pwd`
echo "Entrypoint activated"
echo "Heave ho $NAME"
chmod +x $CWD/goodbye.sh
time=$(date)
echo "::set-output name=time-now::$time"
sh goodbye.sh