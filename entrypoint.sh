#!/bin/sh -l

# INPUTS
NAME=$1
AWS_ACCESS_KEY_ID=$2
AWS_SECRET_ACCESS_KEY=$3
DOCKER_IMAGE=$4
GH_USER=$5
GH_PAT=$6

APP_NAME=`echo $GITHUB_REPOSITORY | cut -d'/' -f 2`
ARGONAUT_WORKSPACE=`pwd`/argonaut-workspace

echo "Heave ho $NAME"
time=$(date)
echo "::set-output name=time-now::$time"

# Prep workspace
mkdir -p $ARGONAUT_WORKSPACE
mkdir -p $ARGONAUT_WORKSPACE/bin
export PATH="$ARGONAUT_WORKSPACE/bin":$PATH

cd $ARGONAUT_WORKSPACE

apk add curl bash zlib-dev binutils jq

# SETUP kubectl
echo "Setting up kubectl"
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv kubectl ./bin

# # SETUP kustomize
# echo "Setting up kustomize"
# curl -s "https://raw.githubusercontent.com/\
# kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
# mv kustomize ./bin

# SETUP aws configure
echo "Setting up aws-cli"
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-bin-2.32-r0.apk
apk add glibc-2.32-r0.apk glibc-bin-2.32-r0.apk

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
aws/install --bin-dir ./bin

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

# Setup kubectl config
aws eks --region us-east-2 update-kubeconfig --name shadowcluster

# Setup ArgoCD
echo "Setting up ArgoCD"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output .status.loadBalancer.ingress[0].hostname`
export ARGO_PWD=`kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2`

# Install ArgoCD CLI
echo "Installing ArgoCD CLI"
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v1.7.8/argocd-linux-amd64
chmod a+x /usr/local/bin/argocd


argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure
argocd cluster list
export CONTEXT_NAME=`kubectl config view -o jsonpath='{.contexts[].name}'`
argocd cluster add $CONTEXT_NAME
export CLUSTER_SERVER=`argocd cluster list | sed -n 2p | cut -d' ' -f 1`

# Create ArgoCD app release
echo "Creating ArgoCD app release"
kubectl create namespace $APP_NAME
argocd app create $APP_NAME+release --repo https://github.com/$GITHUB_REPOSITORY.git --path helm-config --dest-server $CLUSTER_SERVER --dest-namespace $APP_NAME
argocd app sync $APP_NAME+release

# # SETUP argonaut
# curl -s "https://raw.githubusercontent.com/argonautdev/argonaut-actions/master/bin/argonaut-linux-amd64" -o "argonaut"
# mv argonaut ./bin/argonaut
# chmod +x ./bin/argonaut

# # argonaut build
# # argonaut apply


cd ../
# Get the lay of the land
pwd
ls -al
env

# Reading TEST env var
echo "Reading TEST env var: $TEST"
