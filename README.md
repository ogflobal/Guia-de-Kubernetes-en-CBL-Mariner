# Guia-de-Kubernetes-en-CBL-Mariner

![image](https://github.com/ogflobal/Guia-de-Kubernetes-en-CBL-Mariner/assets/74718043/02497865-fe22-4695-850f-4cfb2ff0e629)

```sh
# Crea un nuevo espacio de nombres (namespace) llamado 'my-namespace'
kubectl create namespace my-namespace

# Establece el espacio de nombres 'my-namespace' como el espacio de nombres actual
kubectl config set-context --current --namespace=my-namespace

# Aplica la configuración del archivo YAML ubicado en la URL proporcionada. Este archivo define recursos de Kubernetes en el espacio de nombres 'my-namespace'.
kubectl apply -f https://k8s.io/examples/service/load-balancer-example.yaml --namespace=my-namespace

# Expone el deployment llamado 'hello-world' como un servicio de tipo LoadBalancer con el nombre 'my-service'
kubectl expose deployment hello-world --type=LoadBalancer --name=my-service

# Obtiene información sobre el servicio 'my-service' en el espacio de nombres 'my-namespace'
kubectl get services my-service

# Muestra detalles y describe el servicio 'my-service' para obtener información sobre la configuración del balanceador de carga
kubectl describe services my-service

# Realiza una solicitud HTTP al servicio utilizando la dirección IP del clúster o la dirección IP externa y el puerto especificado
curl http://<cluster-ip|external-ip>:<port>
```
