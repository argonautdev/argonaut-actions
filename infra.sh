#!/bin/sh -l

cd argonaut-configs

# Setup EKS cluster
eksctl create cluster -f _onetimesetup/awsclusterconfig.yaml

# Install ISTIO and the observability stack
curl -L https://istio.io/downloadIstio | sh -
mv istio-1.7.4/bin/istioctl 
chmod a+x istioctl
./istioctl install --set profile=default -f _onetimesetup/istio-setup.yaml
kubectl apply -f _onetimesetup/addons/ -n istio-system


# # Install cert manager using helm
# ## install helm
# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
# ## install cert-manager
# helm repo add jetstack https://charts.jetstack.io
# helm repo update
# helm upgrade --install cert-manager jetstack/cert-manager --set installCRDs=true --namespace cert-manager --create-namespace

# Install cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml

# Issuer in istio-system namespace
kubectl apply -f _onetimesetup/certificate-issuer.yaml 
kubectl apply -f _onetimesetup/certificate.yaml   # Needs wait if secret needs creation

# Install argocd
kubectl create namespace argocd
# OPTIONAL istio injection
kubectl label namespace argocd istio-injection=enabled

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl patch deployment argocd-server --type json -p='[ { "op": "replace", "path":"/spec/template/spec/containers/0/command","value": ["argocd-server","--staticassets","/shared/app","--insecure"] }]' -n argocd


# SETUP INGRESS
kubectl -n istio-system apply -f _onetimesetup/ingress.yaml

# Create the environment
kubectl create namespace dev
kubectl label namespace dev istio-injection=enabled 

# # TODO
# External service provisioning - self service
# Persistent volumes
# Clickhouse
# Hasura

# Print hostname for DNS
echo "ADD THIS loadbalancer ip TO YOUR DNS at aws.tritonhq.io"
kubectl get -n istio-system services | grep ingress