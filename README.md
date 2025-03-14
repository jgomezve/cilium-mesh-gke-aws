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

        kubectl delete ds/kube-proxy -n kube-system

* Install Gateway API CRDs (See Section)


* Install Cilium on EKS

        cilium install   --set gatewayAPI.enabled=true --set kubeProxyReplacement=true --datapath-mode vxlan   --set cluster.id=1   --set cluster.name=eks-cilium   --set eni.enabled=false   --set encapsulation.enabled=true  --set encapsulation.type=vxlan --set ipam.mode=cluster-pool   --set ipam.operator.clusterPoolIPv4PodCIDRList=10.222.0.0/16   --set ipam.operator.clusterPoolIPv4MaskSize=24

* Install AWS Load Balancer Controller

        helm repo add eks https://aws.github.io/eks-charts
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=eks-cilium --set hostNetwork=true --set replicaCount=1

* Set right Python Installation (Optional MacOs)

        export CLOUDSDK_PYTHON=/Library/Frameworks/Python.framework/Versions/3.11/bin/python3.11

* Get Kubeconfig from GKE

        gcloud container clusters get-credentials gke-cilium --zone us-central1-a --project gke-cilium-443902


* Install Cilium on GKE

        cilium install  --datapath-mode vxlan --set encapsulation.enabled=true  --set encapsulation.type=vxlan --set cluster.id=2   --set cluster.name=gke-cilium   --set eni.enabled=false  --set ipam.mode=cluster-pool   --set ipam.operator.clusterPoolIPv4PodCIDRList=10.111.0.0/16   --set ipam.operator.clusterPoolIPv4MaskSize=24

* Rename Kubernetes Contexts

        kubectl config rename-context <> eks
        kubectl config rename-context <> gke

* Install Application on GKE

        kubectl apply -f manifests/bookstore/app_eks.yaml --context eks
        kubectl apply -f manifests/bookstore/app_gke.yaml --context gke
        kubectl apply -f manifests/bookstore/gateway_api.yaml --context eks

* Make Load Balancer Internet Facing
        
        kubectl edit svc cilium-gateway-bookinfo-gateway

* Enable Cluster Mesh

        cilium clustermesh enable --context eks
        cilium clustermesh enable --context gke

* Connect clusters

        cilium clustermesh connect --context eks --destination-context gke

* Scale down Reviews replicas in EKS

        kubectl scale deployment reviews-amazon-aws --replicas=0 --context eks


# Troubleshoot Cluster-Mesh

        kubectl --context eks  -n kube-system exec ds/cilium -- cilium-health status
        kubectl --context eks exec -n kube-system -ti ds/cilium -- cilium-dbg status --all-clusters
        kubectl --context eks exec -it  -n kube-system -ti ds/cilium -- cilium service list

# Install Gateway API

        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml


# Tear Down

        cilium clustermesh disable --context eks
        cilium clustermesh disable --context gke
        kubectl delete -f manifests/bookstore/gateway_api.yaml --context eks


