#!/usr/bin/env bash
# Multicluster
export MULTICLUSTER_ENABLED=false

# K8s Clusters
export GSI_CLUSTER=cluster1
export GSI_CONTEXT=$GSI_CLUSTER
export GSI_NETWORK=$GSI_CLUSTER

# Infrastructure
#export EXTERNAL_DNS_ENABLED=true

# Gateways
export GLOO_EDGE_ENABLED=true

# Testing Apps
export HELLOWORLD_ENABLED=true
export NETSHOOT_ENABLED=true
