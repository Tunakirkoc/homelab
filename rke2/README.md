# K8S Setup on a Proxmox cluster with RKE2 

## Proxmox VMs Setup

### Create the VMs

Create the VMs with the following configuration.

```bash
wget https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

qm create 5081 --name rke2-1 --ostype l26 -machine q35 --bios ovmf --agent 1 --cores 4 --cpu host --memory 8192 --net0 virtio,bridge=DMZ --scsihw virtio-scsi-single --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=1 --scsi0 local-lvm:0,import-from=/root/debian-12-generic-amd64.qcow2 --ide2 local-lvm:cloudinit --serial0 socket --ciuser root --sshkeys /root/.ssh/id_ed25519.pub --ipconfig0 ip=10.0.5.81/24,gw=10.0.5.254 --nameserver 1.1.1.1 --searchdomain kirkoc.net
qm disk resize 5081 scsi0 32G
qm start 5081

qm create 5082 --name rke2-2 --ostype l26 -machine q35 --bios ovmf --agent 1 --cores 4 --cpu host --memory 8192 --net0 virtio,bridge=DMZ --scsihw virtio-scsi-single --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=1 --scsi0 local-lvm:0,import-from=/root/debian-12-generic-amd64.qcow2 --ide2 local-lvm:cloudinit --serial0 socket --ciuser root --sshkeys /root/.ssh/id_ed25519.pub --ipconfig0 ip=10.0.5.82/24,gw=10.0.5.254 --nameserver 1.1.1.1 --searchdomain kirkoc.net
qm disk resize 5082 scsi0 32G
qm start 5082

qm create 5083 --name rke2-3 --ostype l26 -machine q35 --bios ovmf --agent 1 --cores 4 --cpu host --memory 8192 --net0 virtio,bridge=DMZ --scsihw virtio-scsi-single --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=1 --scsi0 local-lvm:0,import-from=/root/debian-12-generic-amd64.qcow2 --ide2 local-lvm:cloudinit --serial0 socket --ciuser root --sshkeys /root/.ssh/id_ed25519.pub --ipconfig0 ip=10.0.5.83/24,gw=10.0.5.254 --nameserver 1.1.1.1 --searchdomain kirkoc.net
qm disk resize 5083 scsi0 32G
qm start 5083
```

## RKE2 Cluster Setup

### Install RKE2 on the first VM

Install RKE2 on the first VM.


```bash
ssh root@10.0.5.81

apt-get install -y qemu-guest-agent
timedatectl set-timezone Europe/Paris
mkdir -p /etc/rancher/rke2
touch /etc/rancher/rke2/config.yaml
echo "token: <YourGeneratedToken>" > /etc/rancher/rke2/config.yaml
echo "tls-san:" >> /etc/rancher/rke2/config.yaml 
echo "  - rke2.kirkoc.net" >> /etc/rancher/rke2/config.yaml

curl -sfL https://get.rke2.io | sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
```

### Install Kube-VIP for Load Balancing the RKE2 API Server

```bash
export VIP=10.0.5.80
export INTERFACE=eth0
export KVVERSION=v0.8.7

alias kube-vip="/var/lib/rancher/rke2/bin/ctr --address /run/k3s/containerd/containerd.sock --namespace k8s.io image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; /var/lib/rancher/rke2/bin/ctr --address /run/k3s/containerd/containerd.sock --namespace k8s.io run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"

kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection

nano /var/lib/rancher/rke2/server/manifests/kube-vip.yaml
```

### Install RKE2 on the other VMs

```bash
ssh root@10.0.5.82
ssh root@10.0.5.83

apt-get install -y qemu-guest-agent
timedatectl set-timezone Europe/Paris
mkdir -p /etc/rancher/rke2
touch /etc/rancher/rke2/config.yaml
echo "server: https://rke2.kirkoc.net:9345" >> /etc/rancher/rke2/config.yaml
echo "token: <YourGeneratedToken>" >> /etc/rancher/rke2/config.yaml
echo "tls-san:" >> /etc/rancher/rke2/config.yaml 
echo "  - rke2.kirkoc.net" >> /etc/rancher/rke2/config.yaml

curl -sfL https://get.rke2.io | sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
```

### Post-Installation of RKE2

On your local machine, run the following commands to configure kubectl.

```bash
# Install kubectl
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

# Install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install helm
```

Copy the kubeconfig file at /etc/rancher/rke2/rke2.yaml and modify the server address to point to the VIP or the loadbalencer domain.

```bash
scp root@10.0.5.81:/etc/rancher/rke2/rke2.yaml ~/.kube/config

# Edit the server address in the kubeconfig file to point to the loadbalencer domain.
nano ~/.kube/config

kubectl get nodes
```

## Install MetalLB for IP Address Management

```bash
helm repo add metallb https://metallb.github.io/metallb
helm repo update

helm install metallb metallb/metallb
```

## Install the Rancher UI using DNS-01 Challenge

```bash
cd ./k8s/rke2

helm repo add jetstack https://charts.jetstack.io 
helm repo update

helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true

kubectl apply -f issuer.yaml

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

kubectl create namespace cattle-system

kubectl apply -f tls-rancher-ingress.yaml
kubectl wait --namespace cattle-system --for=condition=Ready certificate/tls-rancher-ingress --timeout=120s

kubectl describe certificate --namespace cattle-system tls-rancher-ingress

helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=rancher.kirkoc.net --set bootstrapPassword=gnTCzRmThauOycu5tK3nor8k --set ingress.tls.source=secret --set ingress.extraAnnotations.'cert-manager\.io/cluster-issuer'=letsencrypt-prod

kubectl get pods -n cattle-system
```

Now you can access the Rancher UI at https://rancher.kirkoc.net and login with the bootstrap password

## Install the Longhorn Storage

```bash
ssh root@10.0.5.81
export PATH=$PATH:/var/lib/rancher/rke2/bin
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

# For AMD64 platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.7.2/longhornctl-linux-amd64
# For ARM platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.7.2/longhornctl-linux-arm64

chmod +x longhornctl

./longhornctl install preflight

./longhornctl check preflight

rm longhornctl
```
