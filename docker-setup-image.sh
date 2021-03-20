#!/bin/sh -l

echo "$!"
echo "$@"

# Prep workspace
mkdir -p $ART_IMG_WORKSPACE/bin
cd $ART_IMG_WORKSPACE

apk add curl bash zlib-dev binutils openssl
apk add --no-cache git

# SETUP kubectl
echo "Setting up kubectl"
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv kubectl ./bin

# SETUP aws configure
echo "Setting up aws-cli"
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-bin-2.32-r0.apk
apk add glibc-2.32-r0.apk glibc-bin-2.32-r0.apk

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
aws/install --bin-dir ./bin

# SETUP istioctl 1.8.1
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.8.1 TARGET_ARCH=x86_64 sh -
mv istio-1.8.1/bin/istioctl ./bin
chmod a+x istio-1.8.1/bin/istioctl
rm -rf istio-1.8.1/

# SETUP helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# SETUP kustomize
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
chmod a+x kustomize
mv kustomize ./bin

####################
# Install art (compiled for linux/amd64)
echo "installing art"
curl -sL "https://github.com/argonautdev/app-actions/releases/download/v0.1.2/art-linux-amd64" -o art
chmod a+x art
mv art ./bin
####################

# Configure git
git config --global user.name "[ArgonautDev]"
git config --global user.email "argonaut@argonaut.dev"

# Verifying
kubectl version
helm version
istioctl version
aws --version
kustomize version
