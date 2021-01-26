# Dependencies

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
   `istioctl install --set profile=default -y`
2. install prometheus, kiali etc from istioctl download package
   `curl -L https://istio.io/downloadIstio | sh -`
3. `kubectl create ns dev`
   `kubectl label namespace dev istio-injection=enabled`
   `kubectl apply -f scratch/istio-1.8.0/samples/addons/ -n istio-system`
   `helm install wp charts/bitnami/wordpress -n dev`
   `istioctl dashboard grafana`
   `istioctl dashboard kiali`

## Helm

Fill values into templates using `helm template . > _dryrun.yaml`

---

# ISTIO

```
istioctl install --set profile=default -f _onetimesetup/istio-setup.yaml -y
kubectl create ns dev
kubectl label namespace dev istio-injection=enabled
kubectl create ns monitoring
```

## Prometheus

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install -n monitoring prometheus prometheus-community/prometheus

```
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.monitoring.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9090


The Prometheus alertmanager can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-alertmanager.monitoring.svc.cluster.local


Get the Alertmanager URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=alertmanager" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9093
#################################################################################
######   WARNING: Pod Security Policy has been moved to a global property.  #####
######            use .Values.podSecurityPolicy.enabled with pod-based      #####
######            annotations                                               #####
######            (e.g. .Values.nodeExporter.podSecurityPolicy.annotations) #####
#################################################################################


The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
prometheus-pushgateway.monitoring.svc.cluster.local


Get the PushGateway URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9091

```

### Notes

https://prometheus.io/docs/prometheus/latest/configuration/configuration/
https://istio.io/latest/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring

## Jaeger

helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm

### Notes

istio installation requires:
--set values.global.tracer.zipkin.address=<jaeger-collector-address>:9411

`https://github.com/jaegertracing/helm-charts/tree/master/charts/jaeger` has important notes

---

# Notes

## SETUP kustomize

```
echo "Setting up kustomize"
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize ./bin
```

# Certificate management

kubectl -n istio-system describe orders.acme.cert-manager.io
kubectl -n istio-system describe secret ingress-for-istio-wpgkw
kubectl -n istio-system describe certificaterequests.cert-manager.io
kubectl -n istio-system describe certificates.cert-manager.io
kubectl -n istio-system get clusterissuers.cert-manager.io

# IMPORTANT NOTES

1. Istio, after TLS termination, treats the paths as HTTP. Virtual services can use HTTP path based routing subsequent to TLS termination at the gateway.
2. Cert-manager + LetsEncrypt is pretty cool. Install cert-manager with CRDs explicitly using helm. Setup an `Issuer` or `ClusterIssuer` with letsencrypt. Follow that up with creating a `Certificate` (which automatically creates the secret key pair, the request to the CA, and the validation). Once this is done, all you need to do is use the same `Certificate` within your gateway for TLS termination. There are certificate-issue-requests, orders, and other entities also created as a part of this process
3. HTTP-01 solver for cert manager can not be used for wildcard domains. For that, use DNS solver
4. GitLab protected secrets run only on protected branches. Also,there might be issues with secrets that have '\$' in them
5. ArgoCD to track specific branch with `--revision` args.
6. Stateful set port names should be < 15 char
7. Services are set to `httpRewrite` path "/" by default
8. There is a max limit to number of pods per node. That can be set in eksctl in extra config
9. Loki helm upgrades do NOT modify the pods properly and need a pod restart

---

# Grafana dashboards

http://tools.tritonhq.io:3000/grafana/goto/h7dj6yTMk

### Useful charts

https://grafana.com/grafana/dashboards/139
https://grafana.com/grafana/dashboards/8588
https://grafana.com/grafana/dashboards/455
https://grafana.com/grafana/dashboards/707

7630
7636
7645
12153 - maybe not
11454
7249 -> needs to be fixed before use
8588

### AWS

707
139 - doesn't work
650 - load balancer, N/A
617 - EC2
575 - S3

# Scheduling and Autoscaling - hpa and nodegroups

```
eksctl create nodegroup --config-file=/Users/suryaoruganti/company/app-actions/argonaut-configs/_onetimesetup/awsclusterconfig.yaml --include="spot-1"
eksctl --cluster shadow delete nodegroup spot-1
eksctl get --cluster shadow nodegroup

eksctl scale nodegroup --cluster=<clusterName> --nodes=<desiredCount> --name=<nodegroupName> [ --nodes-min=<minSize> ] [ --nodes-max=<maxSize> ]
eksctl scale nodegroup --cluster=shadow --nodes=0 --name=spot-1 --nodes-min=0

eksctl delete cluster -f argonaut-configs/_onetimesetup/awsclusterconfig.yaml
```

## Strategy is important

1. Need to have strategy to scale up nodes and nodegroups based on k8s pod states and descriptions - Insufficient memory, OOMKilled, Too many pods, Insufficient CPU, affinity rules
2. Geometric progression of nodegroups?
3. Need to have strategy to scale pods horizontally
4. Resource management per service to be handled

## TODO

1. Figure out how to do capacity rebalancing for spot instances

# Kubectl fu

```
kubectl -n dev exec hasura-0 -it bash
kubectl -n dev logs hasura-0 argonaut-configs
kubectl logs -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath={.items..metadata.name})
kubectl -n tools edit cm fluent-bit-fluent-bit-loki

kubectl patch pod podname -p '{"metadata":{"finalizers": []}}' --type=merge
```

---

# Flagger

```
helm repo add flagger https://flagger.app
# Flagger's canary CRD
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml

# flagger for istio
helm upgrade -i flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus-server.tools.svc.cluster.local:80
--set slack.url=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK \
--set slack.channel=general \
--set slack.user=flagger
```

slack.url can be replaced with msteams.url for teams.

# crossplane

```
# crossplane cli extends kubectl
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/release-1.0/install.sh | sh
sudo mv kubectl-crossplane /usr/local/bin
kubectl create ns crossplane-system

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm upgrade --install crossplane --namespace crossplane-system crossplane-stable/crossplane


# AWS provider
kubectl crossplane install provider crossplane/provider-aws:v0.16.0

kubectl get provider.pkg --watch

cd tmp
curl -O https://raw.githubusercontent.com/crossplane/crossplane/release-1.0/docs/snippets/configure/aws/providerconfig.yaml
curl -O https://raw.githubusercontent.com/crossplane/crossplane/release-1.0/docs/snippets/configure/aws/setup.sh
chmod a+x setup.sh
./setup.sh --profile default

# these resources are cluster scoped
kubectl apply -f providerconfig.yaml
kubectl apply -f rds.yaml

# TODO: Ensure there is a default VPC

```
