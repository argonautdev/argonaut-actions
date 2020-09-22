#!/bin/sh -l

NAME=$1
CWD=`pwd`
echo "Heave ho $NAME"
time=$(date)
echo "::set-output name=time-now::$time"

# Get the lay of the land
ls -al
pwd
ls -al ../
ps
env

# Prep workspace
ARGONAUT_WORKSPACE="argonaut-workspace"
mkdir -p $ARGONAUT_WORKSPACE
cd $ARGONAUT_WORKSPACE

# SETUP kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
export PATH=$CWD/$ARGONAUT_WORKSPACE:$PATH

# SETUP kustomize
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# SETUP eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

# SETUP aws configure
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# TODO: Incorporate this into argonaut templates https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

# SETUP argonaut
