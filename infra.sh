#!/bin/sh -l

cd argonaut-configs

# Setup EKS cluster
eksctl create cluster -f _onetimesetup/awsclusterconfig.yaml

# If create cluster fails after control plane and before nodegroup setup, kubeconfig is not updated
# aws eks --region us-east-2 update-kubeconfig --name "shadow"

## install helm
# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

kubectl create namespace tools

# Install ISTIO and the observability stack
curl -L https://istio.io/downloadIstio | sh -
mv istio-1.8.0/bin/istioctl .
chmod a+x istioctl
./istioctl install --set profile=default -y -f _onetimesetup/istio-setup.yaml

# Checking if timeout helps with kiali monitoring dashboard creation
kubectl apply -f _onetimesetup/addons/ -n istio-system
# Retry because first time doesn't create all entities
kubectl apply -f _onetimesetup/addons/ -n istio-system


# Install cert manager using helm
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager -n tools -f _onetimesetup/helm-values/cert-manager.yaml 

# # Install cert-manager without helm
# kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml

# Issuer in istio-system namespace
# Needs to wait for certmanager pods to be ready
sleep 20s
kubectl apply -f _onetimesetup/certificate-issuer.yaml # Cluster scoped, not namespace specific
kubectl -n istio-system apply -f _onetimesetup/certificate.yaml   # Needs wait if secret needs creation

# Setup Storage Class to be used by applications
kubectl -n tools apply -f _onetimesetup/storage-class.yaml  # Independent of namespace
# Unset gp2 as default storage class since we are defining our own
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'


# Install argocd
# kubectl create namespace argocd
# OPTIONAL istio injection
# kubectl label namespace tools istio-injection=enabled

# kubectl apply -n tools -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# kubectl patch deployment argocd-server --type json -p='[ { "op": "replace", "path":"/spec/template/spec/containers/0/command","value": ["argocd-server","--staticassets","/shared/app","--insecure"] }]' -n argocd

# # # ArgoCD password reset to 1234567890
# kubectl -n tools patch secret argocd-secret \
#   -p '{"stringData": {
#     "admin.password": "$2a$10$Vnr.0q6Gv/rpMouOaF9dPO4TBgPsflxFQHiOZkKckoTvFiwwwsLYO",
#     "admin.passwordMtime": "'$(date +%FT%T%Z)'"
#   }}'

# ArgoCd Helm Install
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd -n tools -f _onetimesetup/helm-values/argocd.yaml 



# SETUP INGRESS
kubectl -n tools apply -f _onetimesetup/ingress.yaml

# Create the environment
kubectl create namespace dev
kubectl label namespace dev istio-injection=enabled

# # TODO
# External service provisioning - self service
# Persistent volumes
# Clickhouse
# Hasura

rm -rf istio-1.8.0/
rm istioctl

# # HELM INSTALLS
## INSTALL HELM FIRST - TODO
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add loki https://grafana.github.io/loki/charts
# ## Grafana
helm repo update
helm upgrade --install grafana grafana/grafana -n tools -f _onetimesetup/helm-values/grafana.yaml 

# ## Loki
helm upgrade --install loki loki/loki -n tools -f _onetimesetup/helm-values/loki.yaml 

# ## FluentBit - already added the charts for loki
helm upgrade --install fluent-bit loki/fluent-bit -n tools -f _onetimesetup/helm-values/fluent-bit-loki.yaml 

# # FluentBit official install 
# helm repo add fluent https://fluent.github.io/helm-charts
# helm repo add elastic https://helm.elastic.co
# helm repo update

# helm upgrade --install fluent-bit fluent/fluent-bit -n tools -f _onetimesetup/helm-values/fluent-bit.yaml 
# helm upgrade --install elasticsearch elastic/elasticsearch -n tools -f _onetimesetup/helm-values/elasticsearch.yaml 
# helm upgrade --install kibana elastic/kibana -n tools -f _onetimesetup/helm-values/kibana.yaml 
# helm upgrade --install apm-server elastic/apm-server -n tools -f _onetimesetup/helm-values/elastic-apm.yaml 

# Print hostname for DNS
echo "ADD THIS loadbalancer ip TO YOUR DNS at aws.tritonhq.io AND argonaut.tritonhq.io"
kubectl get -n istio-system services | grep ingress