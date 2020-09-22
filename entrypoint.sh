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

apk add curl
apk add bash
apk add zlib-dev
apk add binutils

# SETUP kubectl
echo "Setting up kubectl"
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
export PATH=$CWD/$ARGONAUT_WORKSPACE/bin:$PATH
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
apk add glibc-2.32-r0.apk
apk add glibc-bin-2.32-r0.apk

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
aws/install --bin-dir ./bin

pwd
ls -al
ls -al bin/
# TODO: Incorporate this into argonaut templates https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

# SETUP Go
# apk add --no-cache gcc 
apk add musl-dev openssl go 
# wget -O go.tgz https://golang.org/dl/go1.15.2.linux-amd64.tar.gz
# tar -C /usr/local -xzf go.tgz 
# tar -C /usr/local -xzf go1.15.2.linux-amd64.tar.gz

# cd /usr/local/go/src/ 
# ./make.bash 
export PATH="/usr/local/go/bin:$PATH"
export GOPATH=/go
export PATH=$PATH:$GOPATH/bin 
go version

# SETUP argonaut
apk add git
apk add openssh

# 1. Create the SSH directory.
# 2. Populate the private key file.
# 3. Set the required permissions.
# 4. Add github to our list of known hosts for ssh.

# mkdir -p /root/.ssh/
# echo "$SSH_KEY" > /root/.ssh/id_rsa
# chmod -R 600 /root/.ssh/
# ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Clone a repository (my website in this case)
git clone git@github.com:argonautdev/argonaut.git
cd argonaut
go build
chmod +x argonaut
mv argonaut ../bin/
cd ../

argonaut build
argonaut apply

cd ../

dd if=/dev/zero of=/dev/null