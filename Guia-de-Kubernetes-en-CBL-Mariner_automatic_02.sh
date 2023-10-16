#!/bin/bash

# Solicitar al usuario que ingrese la dirección IP del servidor
read -p "Ingrese la dirección IP del servidor: " SERVER_IP

# Solicitar al usuario que ingrese el nombre del endpoint
read -p "Ingrese el nombre del endpoint: " ENDPOINT_NAME

# Iniciar el clúster de Kubernetes con las direcciones IP y el nombre del endpoint proporcionados
kubeadm init --apiserver-advertise-address=$SERVER_IP --control-plane-endpoint=$ENDPOINT_NAME --pod-network-cidr=192.168.0.0/16

# Crear el directorio para el archivo de configuración de Kubeconfig
mkdir -p $HOME/.kube

# Copiar el archivo de configuración de Kubernetes a la ubicación correcta
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Cambiar la propiedad del archivo de configuración para que sea accesible por el usuario
chown $(id -u):$(id -g) $HOME/.kube/config

# Crear recursos de Calico para la red
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml

# Descargar el archivo de componentes del servidor de métricas
curl -o components.yaml https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Modificar el archivo de componentes para habilitar el modo de conexión segura con Kubelet
sed -i 's/    - --metric-resolution=15s/    - --metric-resolution=15s\n    - --kubelet-insecure-tls=true/g' components.yaml

# Aplicar los componentes al clúster
kubectl apply -f components.yaml

# Observar el estado de los pods en el namespace calico-system
while true; do
    PODS_READY=$(kubectl get pods -n calico-system --no-headers | awk '{print $2}' | grep -E "^([0-9]+)/\1$" | wc -l)
    TOTAL_PODS=$(kubectl get pods -n calico-system --no-headers | wc -l)

    if [ "$PODS_READY" -eq "$TOTAL_PODS" ]; then
        break
    fi

    echo "Esperando a que todos los pods en calico-system estén listos..."
    sleep 5
done

# Quitar las marcas de los nodos que indican que son controladores o maestros
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-


