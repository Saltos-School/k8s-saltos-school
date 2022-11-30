#!/bin/bash -e

if [[ $USER != admin ]]; then
  echo "This script requires an admin session"
  exit 1
fi

CS_K8S_MASTER=k8s-master

mkdir -p /home/admin/.kube
scp $CS_K8S_MASTER:.kube/config .kube/config

sudo mkdir -p /root/.kube
sudo cp /home/admin/.kube/config /root/.kube/config
sudo chown -R root: /root/.kube

kubectl get pods --all-namespaces
