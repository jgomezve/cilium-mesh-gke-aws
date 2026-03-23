# Cilium Cluster Mesh Sandbox

## Structure

* Pre-requisites
* Terraform
* Cloud Networking validation
* Cilium installation on EKS & GKE
* Application Deployment
* Cilium Cluster Mesh


## Pre-requisites

* aws cli
* gcloud cli
* gke-gcloud-auth-plugin

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

        cilium install --version 1.18.5 --set gatewayAPI.enabled=true --set kubeProxyReplacement=true --datapath-mode vxlan   --set cluster.id=1   --set cluster.name=eks-cilium   --set eni.enabled=false   --set encapsulation.enabled=true  --set encapsulation.type=vxlan --set ipam.mode=cluster-pool   --set ipam.operator.clusterPoolIPv4PodCIDRList=10.222.0.0/16   --set ipam.operator.clusterPoolIPv4MaskSize=24

* Install AWS Load Balancer Controller

        helm repo add eks https://aws.github.io/eks-charts
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=eks-cilium --set hostNetwork=true --set replicaCount=1

* Set right Python Installation (Optional MacOs)

        export CLOUDSDK_PYTHON=/Library/Frameworks/Python.framework/Versions/3.11/bin/python3.11

* Get Kubeconfig from GKE

        gcloud container clusters get-credentials gke-cilium --zone us-central1-a --project cilium-mesh-489420


* Install Cilium on GKE

        cilium install  --version 1.18.5 --datapath-mode vxlan --set encapsulation.enabled=true  --set encapsulation.type=vxlan --set cluster.id=2   --set cluster.name=gke-cilium   --set eni.enabled=false  --set ipam.mode=cluster-pool   --set ipam.operator.clusterPoolIPv4PodCIDRList=10.111.0.0/16   --set ipam.operator.clusterPoolIPv4MaskSize=24

* Rename Kubernetes Contexts

        kubectl config rename-context <> eks
        kubectl config rename-context <> gke

* Install Application on GKE

        kubectl apply -f manifests/bookstore/app_eks.yaml --context eks
        kubectl apply -f manifests/bookstore/app_gke.yaml --context gke
        kubectl apply -f manifests/bookstore/gateway_api.yaml --context eks

* Make Load Balancer Internet Facing
        
        kubectl edit svc cilium-gateway-bookinfo-gateway --context eks
        
        service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing

* Enable Cluster Mesh

        cilium clustermesh enable --context eks --service-type LoadBalancer
        cilium clustermesh enable --context gke --service-type LoadBalancer

# To Check

        kubectl annotate service clustermesh-apiserver -n kube-system \
        cloud.google.com/load-balancer-type="Internal" --overwrite

* Connect clusters

        cilium clustermesh connect --context eks --destination-context gke

* Scale down Reviews replicas in EKS


        kubectl patch service reviews --context eks \
        -p '{"metadata":{"annotations":{"service.cilium.io/global":"true"}}}'

        kubectl patch service reviews --context gke \
        -p '{"metadata":{"annotations":{"service.cilium.io/global":"true"}}}'

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



# Cloud networking

## AWS

```bash
aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=eks-cilium*" \
    --query 'Subnets[*].{
        Subnet: Tags[?Key==`Name`].Value | [0],
        CIDR: CidrBlock,
        VpcID: VpcId
    }' \
    --output table
```

```console
-----------------------------------------------------------------------------------
|                                 DescribeSubnets                                 |
+-----------------+-------------------------------------+-------------------------+
|      CIDR       |               Subnet                |          VpcID          |
+-----------------+-------------------------------------+-------------------------+
|  192.168.2.0/24 |  eks-cilium-private-192.168.2.0/24  |  vpc-02e4d622a5eb579a9  |
|  192.168.1.0/24 |  eks-cilium-private-192.168.1.0/24  |  vpc-02e4d622a5eb579a9  |
|  192.168.91.0/24|  eks-cilium-public-192.168.91.0/24  |  vpc-02e4d622a5eb579a9  |
|  192.168.92.0/24|  eks-cilium-public-192.168.92.0/24  |  vpc-02e4d622a5eb579a9  |
+-----------------+-------------------------------------+-------------------------+
```

```bash
aws ec2 describe-vpn-connections \
    --query 'VpnConnections[*].{
        Name: Tags[?Key==`Name`].Value | [0],
        VPN_ID: VpnConnectionId,
        State: State,
        StaticRoutes: Routes[*].DestinationCidrBlock
    }' \
    --output table
```

```console
|+---------------------------------------------------------------------------+|
|                           DescribeVpnConnections                            |
+--------------------+------------+-----------------+-------------------------+
|        Name        |   State    | TransitGateway  |         VPN_ID          |
+--------------------+------------+-----------------+-------------------------+
|  Connection cilium |  available |  None           |  vpn-04855facfea5d724b  |
+--------------------+------------+-----------------+-------------------------+
||                               StaticRoutes                                ||
|+---------------------------------------------------------------------------+|
||  172.25.1.0/24                                                            ||
|+---------------------------------------------------------------------------+|
```

```bash
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].{
        Name: Tags[?Key==`Name`].Value | [0],
        InstanceID: InstanceId,
        State: State.Name,
        SubnetID: SubnetId,
        VpcID: VpcId,
        PrivateIP: PrivateIpAddress
    }[]' \
    --output table
```

```console
------------------------------------------------------------------------------------------------------------------
|                                                DescribeInstances                                               |
+---------------------+-------+----------------+----------+----------------------------+-------------------------+
|     InstanceID      | Name  |   PrivateIP    |  State   |         SubnetID           |          VpcID          |
+---------------------+-------+----------------+----------+----------------------------+-------------------------+
|  i-0597fc696de50049f|  None |  192.168.1.118 |  running |  subnet-075582e905c95f473  |  vpc-0f4141cdd6ffe95ff  |
+---------------------+-------+----------------+----------+----------------------------+-------------------------+
```

## GCP

```bash
gcloud compute networks subnets list \
    --filter="name ~ ^gke-cilium" \
    --format="table(
        ipCidrRange:label=CIDR,
        name:label=SUBNET,
        network.basename():label=VPC_NAME,
        privateIpGoogleAccess:label=PRIVATE_G_ACCESS
    )"
```

```console
CIDR           SUBNET                        VPC_NAME    PRIVATE_G_ACCESS
172.25.1.0/24  gke-cilium--172--25--1--0-24  gke-cilium  True
```

```bash
gcloud compute vpn-tunnels list \
    --format="table(
        name,
        region.basename(),
        vpnGateway.basename():label=GATEWAY,
        peerIp,
        status
    )"
```

```console
NAME     REGION       GATEWAY  PEER_ADDRESS   STATUS
tunnel1  us-central1           50.17.168.138  ESTABLISHED
tunnel2  us-central1           52.44.91.191   ESTABLISHED
```

```bash
gcloud compute routes list \
    --filter="nextHopVpnTunnel:*" \
    --format="table(
        name,
        network.basename():label=VPC,
        destRange:label=DESTINATION_CIDR,
        nextHopVpnTunnel.basename():label=VIA_TUNNEL,
        priority
    )"
```

```console
NAME            VPC         DESTINATION_CIDR  VIA_TUNNEL  PRIORITY
route-cilium-1  gke-cilium  192.168.0.0/16    tunnel1     1000
route-cilium-2  gke-cilium  192.168.0.0/16    tunnel2     1000
```

```bash
gcloud compute instances list \
    --format="table(           
        name,                                    
        networkInterfaces[0].networkIP:label=NODE_IP,
        networkInterfaces[0].subnetwork.basename():label=SUBNET,
        networkInterfaces[0].aliasIpRanges[0].ipCidrRange:label=POD_RANGE
    )"   
```            
```console
NAME                                           NODE_IP     SUBNET                        POD_RANGE
gke-gke-cilium-gke-cilium-nodes-b5b3d145-hr3k  172.25.1.4  gke-cilium--172--25--1--0-24
```

```bash
cilium-mesh-gke-aws % aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[*].{Name:LoadBalancerName, State:State.Code, Scheme:Scheme, Subnets:AvailabilityZones[*].SubnetId}' \
    --output table
```



```console
------------------------------------------------------------------
|                      DescribeLoadBalancers                     |
+----------------------------------+-------------------+---------+
|               Name               |      Scheme       |  State  |
+----------------------------------+-------------------+---------+
|  k8s-default-ciliumga-302d831e91 |  internet-facing  |  active |
+----------------------------------+-------------------+---------+
||                            Subnets                           ||
|+--------------------------------------------------------------+|
||  subnet-0805fe839c8e0cb5d                                    ||
|+--------------------------------------------------------------+|
```