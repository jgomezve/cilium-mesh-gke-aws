# Cilium Cluster Mesh Sandbox

Terraform project to deploy Kubernetes clusters on AWS and GCP interconnected over a Site-to-Site VPN. The projects does not use best-practices to deploy cloud infrastructure on the Cloud. The goal is to deploy de underlay required to connect EKA and GKE cluster with Cilium using Cilium Mesh.

## Useful commands

* Get Kubeconfig contexts

        kubectl config get-contexts

* Rename a Kubeconfig context

        kubectl config rename-context <old_context_name> <new_context_name>

* Set default context

        kubectl config use-context <context_name>

* Delete a Kubeconfig context

        kubectl config delete-context <context_name>

## Instructions

* Get Kubeconfig from EKS

        aws eks update-kubeconfig --region us-east-1 --name eks-cilium 


* Delete Kube-Proxy DaemonSet (Kube-Proxy replacement is required for Cilium GW API)



* Install Cilium on EKS

        cilium install   --set gatewayAPI.enabled=true --set kubeProxyReplacement=true --datapath-mode vxlan   --set cluster.id=1   --set cluster.name=eks-cilium   --set eni.enabled=false   --set encapsulation.enabled=true  --set encapsulation.type=vxlan --set ipam.mode=cluster-pool   --set ipam.operator.clusterPoolIPv4PodCIDRList=10.222.0.0/16   --set ipam.operator.clusterPoolIPv4MaskSize=24

* Install AWS Load Balancer Controller

        helm repo add eks https://aws.github.io/eks-charts
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=eks-cilium --set hostNetwork=true --set replicaCount=1

* Get Kubeconfig from GKE

        gcloud container clusters get-credentials gke-cilium --zone us-central1-a --project gke-cilium-443902


* Install Cilium on GKE

        cilium install  --datapath-mode vxlan --set encapsulation.enabled=true  --set encapsulation.type=vxlan --set cluster.id=2   --set cluster.name=gke-cilium   --set eni.enabled=false  --set ipam.mode=cluster-pool   --set ipam.operator.clusterPoolIPv4PodCIDRList=10.111.0.0/16   --set ipam.operator.clusterPoolIPv4MaskSize=24

* Enable Cluster Mesh

        cilium clustermesh enable --context eks
        cilium clustermesh enable --context gke

* Connect clusters

        cilium clustermesh connect --context eks --destination-context gke


# Troubleshoot Cluster-Mesh


# TearDown

