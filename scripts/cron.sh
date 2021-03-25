#! /bin/bash

NAMESPACE=$1

kubectl -n istio-system get secret ingress-letsencrypt -o json > secret.json
cat secret.json | jq '.data."tls.crt"' | base64 -d > letsencrypt.crt
cat secret.json | jq '.data."tls.key"' | base64 -d > letsencrypt.key
kubectl -n $NAMESPACE delete secret beamd-letsencrypt
kubectl -n $NAMESPACE create secret tls beamd-letsencrypt --cert=letsencrypt.crt --key=letsencrypt.key

echo "$NAMESPACE ns"