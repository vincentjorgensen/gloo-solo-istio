#!/usr/bin/env bash
# Multicluster
export MULTICLUSTER_ENABLED=true

# K8s Clusters
export GSI_CLUSTER1=cluster1
export GSI_CONTEXT1="$GSI_CLUSTER1"
export GSI_NETWORK1="$GSI_CLUSTER1"
export GSI_TRUST_DOMAIN1="cluster.local"

export GSI_CLUSTER2=cluster2
export GSI_CONTEXT2="$GSI_CLUSTER2"
export GSI_NETWORK2="$GSI_CLUSTER2"
export GSI_TRUST_DOMAIN2="cluster.local"

export GSI_CLUSTER3=cluster3
export GSI_CONTEXT3="$GSI_CLUSTER3"
export GSI_NETWORK3="$GSI_CLUSTER3"
export GSI_TRUST_DOMAIN3="cluster.local"

###export GSI_CLUSTER4=cluster4
###export GSI_CONTEXT4="$GSI_CLUSTER4"
###export GSI_NETWORK4="$GSI_CLUSTER4"

# Infrastructure
export EXTERNAL_DNS_ENABLED=true
export AMBIENT_ENABLED=true

# Gateway
export GLOO_GATEWAY_V2_ENABLED=true

# Test Apps
export HELLOWORLD_ENABLED=true
export NETSHOOT_ENABLED=true
