#!/bin/sh -l

# Install ISTIO and the observability stack
curl -L https://istio.io/downloadIstio | sh -
mv istio-1.7.4/bin/istioctl .
chmod a+x istioctl
./istioctl install --set profile=default -f _onetimesetup/istio-setup.yaml
kubectl apply -f scratch/istio-1.7.4/samples/addons/ -n istio-system

# Install argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Create the environment
kubectl create namespace dev
kubectl label namespace dev istio-injection=enabled 

# # TODO
# External service provisioning - self service
# Persistent volumes

# cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml
