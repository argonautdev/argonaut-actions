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
mkdir -p bin

apk add curl bash zlib-dev binutils

# SETUP kubectl
echo "Setting up kubectl"
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
export PATH=$CWD/$ARGONAUT_WORKSPACE/bin:$PATH
# export PATH=/argonaut-workspace/bin:$PATH
mv kubectl ./bin

# SETUP kustomize
echo "Setting up kustomize"
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize ./bin

# SETUP eksctl
echo "Setting up eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s | awk '{print tolower($0)}')_amd64.tar.gz" | tar xz -C ./
mv eksctl ./bin

# SETUP aws configure
echo "Setting up aws-cli"
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-bin-2.32-r0.apk
apk add glibc-2.32-r0.apk glibc-bin-2.32-r0.apk

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
aws/install --bin-dir ./bin

pwd
ls -al
ls -al bin/
# TODO: Incorporate this into argonaut templates https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

# SETUP argonaut
curl -s "https://raw.githubusercontent.com/argonautdev/argonaut-actions/master/bin/argonaut-linux-amd64" -o "argonaut"
mv argonaut ./bin/argonaut
chmod +x ./bin/argonaut
argonaut

# argonaut build
# argonaut apply

# cd ../

# dd if=/dev/zero of=/dev/null