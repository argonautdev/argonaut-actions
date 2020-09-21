#!/bin/sh -l

NAME=$1
CWD=`pwd`
echo "Heave ho $NAME"
time=$(date)
echo "::set-output name=time-now::$time"

chmod +x $CWD/goodbye.sh
sh goodbye.sh