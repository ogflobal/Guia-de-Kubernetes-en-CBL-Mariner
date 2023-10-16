# Guia-de-Kubernetes-en-CBL-Mariner

![image](https://github.com/ogflobal/Guia-de-Kubernetes-en-CBL-Mariner/assets/74718043/02497865-fe22-4695-850f-4cfb2ff0e629)

```sh
kubectl create namespace my-namespace
kubectl config set-context --current --namespace=my-namespace
kubectl apply -f https://k8s.io/examples/controllers/nginx-deployment.yaml namespace=my-namespace

kubectl get deployments hello-world
kubectl describe deployments hello-world

kubectl get replicasets
kubectl describe replicasets

kubectl expose deployment hello-world --type=LoadBalancer --name=my-service

kubectl get services my-service

kubectl describe services my-service

kubectl get pods --output=wide

curl http://<cluster-ip|external-ip>:<port>
```
