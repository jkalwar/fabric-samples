#!/bin/bash

# Script to bring the cluster up

set -e

REGION_NAME=eastus
RESOURCE_GROUP=test-network
SUBNET_NAME=test-network-subnet1
VNET_NAME=test-network-vnet
AKS_CLUSTER_NAME=test-network-cluster

echo "Creating the cluster with the following paramters"

echo "REGION_NAME=$REGION_NAME"
echo "RESOURCE_GROUP=$RESOURCE_GROUP"
echo "SUBNET_NAME=$SUBNET_NAME"
echo "VNET_NAME=$VNET_NAME"
echo "AKS_CLUSTER_NAME=$AKS_CLUSTER_NAME"


echo "Creating the resource group"
#create the resource group
az group create \
    --name $RESOURCE_GROUP \
    --location $REGION_NAME

#create the vnet and then later specify the netoworking model while deploying the cluster.
# Kubenet networking  OR Azure Container Networking Interface
echo "Creating the VNET"
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --location $REGION_NAME \
    --name $VNET_NAME \
    --address-prefixes 10.2.0.0/16 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix 10.2.0.0/18

# get the latest non preview version of kubernetes in your region.
echo "Getting the stable version of kubernetes"

VERSION=$(az aks get-versions \
    --location $REGION_NAME \
    --query 'orchestrators[?!isPreview] | [-1].orchestratorVersion' \
    --output tsv)

echo "VERSION=$VERSION"

SUBNET_ID=$(az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --query [].id --output tsv) 

echo "Creating AKS Cluster"
# create the aks cluster with the azure cni
# Detailed explanation of the options is available here : https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest

az aks create \
--resource-group $RESOURCE_GROUP \
--name $AKS_CLUSTER_NAME \
--vm-set-type VirtualMachineScaleSets \
--load-balancer-sku standard \
--location $REGION_NAME \
--kubernetes-version $VERSION \
--network-plugin azure \
--vnet-subnet-id $SUBNET_ID \
--service-cidr 10.5.0.0/24 \
--dns-service-ip 10.5.0.10 \
--docker-bridge-address 172.18.0.1/16 \
--generate-ssh-keys \
--node-count 2 \
--max-pods 120 \
--node-vm-size "Standard_B2s" --service-principal XXXXXX --client-secret XXXXXX --nodepool-name "dcpoo1" 


#kubectl is the main Kubernetes command-line client you use to interact with your cluster and is available in Cloud Shell. A cluster context is required to allow kubectl to connect to a cluster. The context contains the cluster's address, a user, and a namespace. Use the az aks get-credentials command to configure your instance of kubectl.
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME

#To test if the kubectl commands are working.
kubectl get nodes









