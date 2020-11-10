#!/bin/sh -l

# INPUTS
ENV_NAME=$1
AWS_ACCESS_KEY_ID=$2
AWS_SECRET_ACCESS_KEY=$3
DOCKER_IMAGE=$4
DOCKER_IMAGE_TAG=$5
DOCKER_IMAGE_ACCESS_TOKEN=$6
GIT_USER=$7
GIT_PUSH_TOKEN=$8
# DOCKER_IMAGE_DIGEST=$9

CLUSTER_NAME="shadow"

APP_NAME=$CI_PROJECT_NAME
ARGONAUT_WORKSPACE=`pwd`/argonaut-workspace
CONFIG_PATH=`pwd`/argonaut-configs


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

# SETUP aws configure
echo "Setting up aws-cli"
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-bin-2.32-r0.apk
apk add glibc-2.32-r0.apk glibc-bin-2.32-r0.apk

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
aws/install --bin-dir ./bin

# This export is redundant?
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

# Setup kubectl config
aws eks --region us-east-2 update-kubeconfig --name $CLUSTER_NAME

# Install ArgoCD CLI
echo "Installing ArgoCD CLI"

export ARGOCD_SERVER="aws.tritonhq.io"
# export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output .status.loadBalancer.ingress[0].hostname`
export ARGO_PWD=`kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2`

curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v1.7.8/argocd-linux-amd64
chmod a+x /usr/local/bin/argocd

# Access the argocd operator
# argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure
argocd login $ARGOCD_SERVER --username admin --password "1234567890" --insecure --grpc-web
export CONTEXT_NAME=`kubectl config view -o jsonpath='{.contexts[].name}'`
argocd cluster add $CONTEXT_NAME
# If there are multiple clusters, need to pick the right one
export CLUSTER_SERVER=`argocd cluster list | sed -n 2p | cut -d' ' -f 1`


# Ensure sufficient permissions for reading image
kubectl create secret -n $ENV_NAME docker-registry image-pull-secret --docker-username=argonautdev --docker-password=$DOCKER_IMAGE_ACCESS_TOKEN --docker-email=argonaut@argonaut.dev --docker-server=ghcr.io
### TODO: Update pod deployment spec to have imagePullSecrets
### TODO: Create secret should move to cluster and app bootstrap with possibility to update it from here??

# Update docker image with latest tag
cd $CONFIG_PATH

# Install yq
wget -O $ARGONAUT_WORKSPACE/bin/yq "https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_amd64"
chmod a+x $ARGONAUT_WORKSPACE/bin/yq

yq w -i values.yaml image $DOCKER_IMAGE
yq w -i values.yaml imageTag $DOCKER_IMAGE_TAG
echo "Updated values file tag"

# Print ENV
env

# Create ArgoCD app release
echo "Creating ArgoCD app release"
echo "Adding repo: argocd repo add https://gitlab.com/$CI_PROJECT_PATH.git --username $GIT_USER --password $GIT_PUSH_TOKEN --upsert
"
argocd repo add https://gitlab.com/$CI_PROJECT_PATH.git --username $GIT_USER --password $GIT_PUSH_TOKEN --upsert
echo "Creating argo app"
echo "$APP_NAME-release --repo https://gitlab.com/$CI_PROJECT_PATH.git --path argonaut-configs --dest-server $CLUSTER_SERVER --dest-namespace $ENV_NAME --auto-prune --sync-policy automated --upsert"
argocd app create "$APP_NAME-release" --repo https://gitlab.com/$CI_PROJECT_PATH.git --path argonaut-configs --dest-server $CLUSTER_SERVER --dest-namespace $ENV_NAME --auto-prune --sync-policy automated --upsert
echo "Syncing argo app"
argocd app sync "$APP_NAME-release"

cd ../

# echo "Git commit of new image (excluding tmp files)"

# # Get the lay of the land
# pwd
# ls -al
# env
echo "Exiting script"