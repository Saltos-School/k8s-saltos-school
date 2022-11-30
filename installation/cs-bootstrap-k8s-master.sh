#!/bin/bash -e

if [[ $USER != root ]]; then
  echo "This script requires root privileges"
  exit 1
fi

#echo "cgroup-driver=systemd/cgroup-driver=cgroupfs" > /etc/default/kubelet

kubeadm init --pod-network-cidr=192.168.0.0/16

export KUBECONFIG=/etc/kubernetes/admin.conf

mkdir -p /home/admin/.kube
cp /etc/kubernetes/admin.conf /home/admin/.kube/config
chown -R admin: /home/admin/.kube

mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chown -R root: /root/.kube

echo "Waiting for Kubernetes control plane"
sleep 120

mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/calico.conf <<EOF
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali
EOF

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml

echo "Waiting for Tigera containers"
sleep 120

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml

echo "Waiting for Calico containers"
sleep 120

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

curl -L https://github.com/projectcalico/calico/releases/download/v3.24.5/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
chmod +x /usr/local/bin/calicoctl
calicoctl node status
