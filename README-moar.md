# AWS deployments

After `aws configure` is run, `eksctl create cluster mycluster -f aws/awsclusterconfig.yaml` will create nodes (infra layer)
Running `kubectl apply -f aws/awsexample.yaml` will create a deployment with the right load balancer and images setup (app layer)

Run `kubectl -n dev exec --stdin --tty <PODNAME> -- /bin/sh` to get a shell into the pod

    Note: Naked pod deployments are not best practice

Run the following to setup local kubectl config to the AWS instance

```
aws eks --region region update-kubeconfig --name cluster_name
```

# Read Secrets (wordpress)

## kubectl get secret --namespace default wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode

kubectl create secret generic regcred \
 --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
 --type=kubernetes.io/dockerconfigjson

kubectl apply -f local/pod.yaml
kubectl -n dev get pods -w
kubectl -n dev describe pod guinea-pod
kubectl -n dev delete pod guinea-pod
kubectl create ns dev

kubectl create secret -n dev docker-registry ghcr --docker-username=argonautdev --docker-password=efb84c6f7cdb50067f97024bddcabd18a740f700 --docker-email=suryaoruganti@gmail.com --docker-server=ghcr.io

kubectl get secret -n dev ghcr --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
echo XYZ| base64 --decode

kubectl delete secret -n dev ghcr

kubectl replace serviceaccount default -f serviceaccount.yaml
kubectl get serviceaccounts -o yaml

---
# Docker stuff to run

```
docker build -t amazingapp:dev .
docker-compose up
```

`https://localhost:3000` will load the app

## Useful docker commands

```
docker run -p 3000:3000 --rm -d -i -t --name amazingapp amazingapp:dev
docker exec -it amazingapp /bin/sh
```

---

# AWS ECR

Format `aws_account_id.dkr.ecr.region.amazonaws.com/my-web-app`

```

docker tag <imageID> 363397145679.dkr.ecr.us-east-2.amazonaws.com/amazingapp:latest
docker push 363397145679.dkr.ecr.us-east-2.amazonaws.com/amazingapp:latest

```

If auth token is expired, run `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 363397145679.dkr.ecr.us-east-2.amazonaws.com`

### Follow logs from container

```
kubectl -n <NAMESPACE> logs <PODNAME> -f
```

### Print logs from exited container

```
kubectl -n <NAMESPACE> logs <PODNAME> -p
```

---

# Docker demos

Your container should print "Hello!" then exit. We can now look up that container by name

    docker ps --all --filter name=hello

We can stop the app from another terminal window

    docker kill hello-app

## Local application development

We want to use docker during development without having to rebuild between each change.

    docker build -t node-demo-app-dev ./application --file ./application/Dockerfile.dev

Since we're going to mount all of our code, let's install our deps on our machine

    cd application && npm install && cd ..

Let's mount our code as a volume so local changes will appear inside the container.

    docker run --name hello-app-dev -p 3000:3000 -v `pwd`/application/:/app node-demo-app-dev

Now make a change to the application and see the change take effect instantly!

---
