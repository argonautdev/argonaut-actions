#!/bin/sh -l

ENV_NAME=dev
TOOLS_NS=tools
ARGONAUT_WS=argonaut-configs
SETUP_CONFIGS=_onetimesetup

cd $ARGONAUT_WS

## install helm
# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
## Install kubectl, eksctl, copy istio binary

# Setup EKS cluster
eksctl create cluster -f $SETUP_CONFIGS/awsclusterconfig.yaml

# If create cluster fails after control plane and before nodegroup setup, kubeconfig is not updated
# aws eks --region us-east-2 update-kubeconfig --name "shadow"



# Cluster configurations
# Create the environment
kubectl create namespace $ENV_NAME
kubectl label namespace $ENV_NAME istio-injection=enabled
kubectl create namespace $TOOLS_NS

# Setup Storage Class to be used by applications
kubectl apply -f $SETUP_CONFIGS/storage-class.yaml  # Independent of namespace
# Unset gp2 as default storage class since we are defining our own
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Install ISTIO and the observability stack
curl -L https://istio.io/downloadIstio | sh -
mv istio-1.8.0/bin/istioctl .
chmod a+x istioctl
./istioctl install --set profile=default -y -f $SETUP_CONFIGS/istio-setup.yaml

rm -rf istio-1.8.0/
rm istioctl

# HELM Charts - repo add
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add kiali https://kiali.org/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add loki https://grafana.github.io/loki/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# HELM Installs
# Prometheus server and node exporter
helm upgrade --install prometheus prometheus-community/prometheus -n $TOOLS_NS -f $SETUP_CONFIGS/helm-values/prometheus.yaml 
# Fluent-Bit
helm upgrade --install fluent-bit loki/fluent-bit -n $TOOLS_NS -f $SETUP_CONFIGS/helm-values/fluent-bit-loki.yaml
# Grafana
helm upgrade --install grafana grafana/grafana -n $TOOLS_NS -f $SETUP_CONFIGS/helm-values/grafana.yaml 
# Loki
helm upgrade --install loki loki/loki -n $TOOLS_NS -f $SETUP_CONFIGS/helm-values/loki-temp.yaml 
# Cert-Manager
helm upgrade --install cert-manager jetstack/cert-manager -n $TOOLS_NS -f $SETUP_CONFIGS/helm-values/cert-manager.yaml 
# ArgoCd
helm upgrade --install argocd argo/argo-cd -n $TOOLS_NS -f $SETUP_CONFIGS/helm-values/argocd.yaml 

# Install Jaeger - without persistence or a data store - TODO
# TODO: The jaeger UI doesn't work because the base-path is to be changed to /jaeger
helm upgrade --install -n $TOOLS_NS jaeger jaegertracing/jaeger-operator --set jaeger.create=true --set fullnameOverride=jaeger 
# helm upgrade --install -n $TOOLS_NS jaeger jaegertracing/jaeger -f $SETUP_CONFIGS/helm-values/jaeger.yaml
# kubectl apply -f $SETUP_CONFIGS/addons/jaeger.yaml -n $TOOLS_NS

# Install Kiali
helm upgrade --install kiali-operator kiali/kiali-operator -n $TOOLS_NS -f $SETUP_CONFIGS/helm-values/kiali-operator-service.yaml

# Setup Cluster Certificate Issuer in istio-system namespace. Needs to wait for certmanager pods to be ready
kubectl apply -f $SETUP_CONFIGS/certificate-issuer.yaml # Cluster scoped, not namespace specific
# Setup Certificate in istio-system namespace. Do not forget to add DNS for new domains. Needs wait for new domains.
kubectl -n istio-system apply -f $SETUP_CONFIGS/certificate.yaml
# Setup Ingress
kubectl -n $TOOLS_NS apply -f $SETUP_CONFIGS/ingress.yaml

# Print hostname for DNS
echo "ADD THIS loadbalancer ip TO YOUR DNS at aws.tritonhq.io AND tools.tritonhq.io AND app.tritonhq.io"
kubectl get -n istio-system services | grep ingress