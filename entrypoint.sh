#!/bin/sh -l

# INPUTS
NAME=$1
AWS_ACCESS_KEY_ID=$2
AWS_SECRET_ACCESS_KEY=$3

ARGONAUT_WORKSPACE="./argonaut-workspace"
AWS_CONFIG_FILE="$ARGONAUT_WORKSPACE/.aws/config"   # "~/.aws/config"
AWS_SHARED_CREDENTIALS_FILE="$ARGONAUT_WORKSPACE/.aws/credentials" # "~/.aws/credentials"

echo "Heave ho $NAME"
time=$(date)
echo "::set-output name=time-now::$time"

# Prep workspace
mkdir -p $ARGONAUT_WORKSPACE
mkdir -p $ARGONAUT_WORKSPACE/bin
mkdir -p $ARGONAUT_WORKSPACE/.aws
export PATH="$ARGONAUT_WORKSPACE/bin":$PATH

cd $ARGONAUT_WORKSPACE

touch $AWS_CONFIG_FILE
touch $AWS_SHARED_CREDENTIALS_FILE


apk add curl bash zlib-dev binutils

# SETUP kubectl
echo "Setting up kubectl"
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv kubectl ./bin

# SETUP kustomize
echo "Setting up kustomize"
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize ./bin

# SETUP eksctl
echo "Setting up eksctl"
curl -s --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s | awk '{print tolower($0)}')_amd64.tar.gz" | tar xz -C ./
mv eksctl ./bin

# SETUP aws configure
echo "Setting up aws-cli"
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-bin-2.32-r0.apk
apk add glibc-2.32-r0.apk glibc-bin-2.32-r0.apk

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
aws/install --bin-dir ./bin

echo "[default]\
aws_access_key_id=$AWS_ACCESS_KEY_ID \
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" > $AWS_SHARED_CREDENTIALS_FILE

echo "[default] \
output=json" > $AWS_CONFIG_FILE
# region=us-west-2 \

echo "aws secrets are not printed, see: $AWS_ACCESS_KEY_ID and $AWS_SECRET_ACCESS_KEY"

# SETUP argonaut
curl -s "https://raw.githubusercontent.com/argonautdev/argonaut-actions/master/bin/argonaut-linux-amd64" -o "argonaut"
mv argonaut ./bin/argonaut
chmod +x ./bin/argonaut

argonaut build
# argonaut apply

cd ../
# Get the lay of the land again
pwd
ls -al
env
cat $AWS_CONFIG_FILE
cat $AWS_SHARED_CREDENTIALS_FILE

# Reading TEST env var
echo "Reading TEST env var: $TEST"
# dd if=/dev/zero of=/dev/null