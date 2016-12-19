#!/bin/bash
BASE_FQDN=${BASE_FQDN:-"test.verloop.io"}
CLUSTER_DOMAIN="k8s.$BASE_FQDN"
# PS: the following command will bring the cluster up
kops update cluster $CLUSTER_DOMAIN --yes

# Install heapster and dashboard

kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/v1.4.3/addons/monitoring-standalone/v1.2.0.yaml
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.5.0/src/deploy/kubernetes-dashboard.yaml