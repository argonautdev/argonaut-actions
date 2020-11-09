
# Install cert manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --set installCRDs=true --namespace cert-manager --create-namespace

# Issuer in istio-system nameespace
kubectl apply -f _onetimesetup/issuer.yaml 
kubectl apply -f _onetimesetup/cert.yaml   # Needs wait if secret needs creation

# ARGOCD install
kubectl create ns argocd
# OPTIONAL
kubectl label namespace argocd istio-injection=enabled
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


# Optional (?)
kubectl patch deployment argocd-server --type json -p='[ { "op": "replace", "path":"/spec/template/spec/containers/0/command","value": ["argocd-server","--staticassets","/shared/app","--insecure"] }]' -n argocd

# SETUP INGRESS
kubectl -n argocd apply -f argonaut-configs/_onetimesetup/ingress.yaml