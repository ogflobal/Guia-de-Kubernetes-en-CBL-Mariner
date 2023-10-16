#!/bin/bash

# Actualiza el sistema
tdnf -y update

# Ingresa el hostname
read -p "Ingresa el nombre del host (por ejemplo, vm2.192.168.0.102.nip.io): " hostname_input
hostnamectl set-hostname "$hostname_input" --static
sed -i "s/127.0.0.1   $HOSTNAME/127.0.0.1   $hostname_input/g" /etc/hosts

# Configura la dirección IP y la puerta de enlace
read -p "Ingresa la dirección IP y la máscara de red (por ejemplo, 192.168.0.102/24): " address_input
read -p "Ingresa la puerta de enlace (por ejemplo, 192.168.0.1): " gateway_input
cat > /etc/systemd/network/01-static-en.network << EOF
[Match]
Name=eth0

[Network]
Address=$address_input
Gateway=$gateway_input
EOF
chmod 644 /etc/systemd/network/01-static-en.network

# Configura los servidores de nombres en un bucle
nameservers=()
while true; do
    read -p "Ingresa un servidor de nombres (por ejemplo, 190.113.220.18): " nameserver_input
    nameservers+=("nameserver $nameserver_input\n")
    read -p "¿Deseas ingresar otro servidor de nombres? (y/n): " continue_input
    if [ "$continue_input" != "y" ]; then
        break
    fi
done
nameservers_str=$(IFS=' '; echo "${nameservers[*]}")
sed -i "s/nameserver 127.0.0.53/$nameservers_str/g" /etc/resolv.conf

# Configura la búsqueda
read -p "Ingresa la cadena de búsqueda (por ejemplo, 192.168.0.102.nip.io): " search_input
sed -i "s/search ./search $search_input/g" /etc/resolv.conf

# Deshabilita iptables
systemctl disable iptables
systemctl stop iptables

# Carga módulos del kernel
modprobe overlay
modprobe br_netfilter

# Habilita el enrutamiento IP
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.d/50-security-hardening.conf
tee /etc/sysctl.d/01-K8s.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Instala paquetes necesarios
tdnf -y install ebtables ethtool socat conntrack dnsmasq moby-engine kubernetes-client kubernetes-kubeadm

# Habilita y arranca Docker
systemctl enable --now docker.service

# Agrega el usuario obtenido de la sesión al grupo "docker"
usermod -aG docker "$USER"
newgrp docker

# Solicitar al usuario que ingrese la dirección IP del servidor
read -p "Ingrese la dirección IP del servidor: " SERVER_IP

# Solicitar al usuario que ingrese el nombre del endpoint
read -p "Ingrese el nombre del endpoint: " ENDPOINT_NAME

# Iniciar el clúster de Kubernetes con las direcciones IP y el nombre del endpoint proporcionados
sudo kubeadm init --apiserver-advertise-address=$SERVER_IP --control-plane-endpoint=$ENDPOINT_NAME --pod-network-cidr=192.168.0.0/16

# Crear el directorio para el archivo de configuración de Kubeconfig
mkdir -p $HOME/.kube

# Copiar el archivo de configuración de Kubernetes a la ubicación correcta
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Cambiar la propiedad del archivo de configuración para que sea accesible por el usuario
sudo chown $(id -u):$(id -g) $HOME/.kube/config

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


