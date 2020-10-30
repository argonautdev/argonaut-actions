# Deps

brew install jq
brew install argocd

# install argocd on cluster

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose the admin panel

## Local

kubectl port-forward svc/argocd-server -n argocd 8080:443

## AWS

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

user: admin
password: `kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2`

export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output .status.loadBalancer.ingress[0].hostname`
export ARGO_PWD=`kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2`

argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure
argocd account update-password

argocd cluster list
export CONTEXT_NAME=`kubectl config view -o jsonpath='{.contexts[].name}'`
`argocd cluster add $CONTEXT_NAME`

## Connect to Git

```
kubectl create namespace amazingapp
// Set $CLUSTER_SERVER
export CLUSTER_SERVER=`argocd cluster list | sed -n 2p | cut -d' ' -f 1`
argocd app create amazingapp --repo https://github.com/argonautdev/amazingapp.git --path helm-config --dest-server $CLUSTER_SERVER --dest-namespace amazingapp
argocd app sync amazingapp
```

```
kubectl create namespace guestbook
// Set $CLUSTER_SERVER
export CLUSTER_SERVER=`argocd cluster list | sed -n 2p | cut -d' ' -f 1`
argocd app create guestbook-app --dest-namespace guestbook --dest-server $CLUSTER_SERVER --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook
argocd app sync guestbook-app
```

NOTES:

- CLUSTER_SERVER is obtained from running `argocd cluster list`
- The "path" flag is important as it contains the configurations that will be executed by argo
- `argocd app list` and `argocd cluster list` are useful commands

# The Helm way to install argo on cluster

Source: https://medium.com/@andrew.kaczynski/gitops-in-kubernetes-argo-cd-and-gitlab-ci-cd-5828c8eb34d6

NOTE: Need to modify this for running on EKS

helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd -n argocd argo/argocd --values values.yaml

With `values.yaml` file being:

```
appVersion: "1.4.2"
version: 1.8.7
server:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: "nginx"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    hosts:
      - argocd.minikube.local
```

# Connecting to a private docker registry

```
kubectl create secret docker-registry regsecret --docker-server=ghcr.io --docker-username=argonautdev --docker-password=$GH_PAT --docker-email=suryaoruganti@gmail.com
```

---

# ISTIO setup and addons

1. install istioctl
   `istioctl install --profile=demo`
2. install prometheus, kiali etc from istioctl download package
   `curl -L https://istio.io/downloadIstio | sh -`
3. `kubectl create ns dev`
   `kubectl label namespace dev istio-injection=enabled`
   `kubectl apply -f scratch/istio-1.7.4/samples/addons/ -n istio-system`
   `helm install wp charts/bitnami/wordpress -n dev`
   `istioctl dashboard grafana`
   `istioctl dashboard kiali`

---

# Notes

## SETUP kustomize

```
echo "Setting up kustomize"
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize ./bin
```
