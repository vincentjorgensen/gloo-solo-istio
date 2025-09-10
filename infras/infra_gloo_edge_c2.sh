#!/usr/bin/env bash
# Clusters, single cluster, MGMT is same as workload
export GSI_MGMT_CLUSTER=cluster2
export GSI_MGMT_CONTEXT=cluster2
export GSI_MGMT_NETWORK=cluster2
export GSI_CLUSTER=cluster2
export GSI_CONTEXT=cluster2
export GSI_NETWORK=cluster2

# Infrastructure
export SIDECAR_ENABLED=false
###export GME_ENABLED=true
###export GME_MGMT_AGENT_ENABLED=true

# Testing Apps
export HELLOWORLD_ENABLED=true
export HTTPBIN_ENABLED=true
export CURL_ENABLED=true
export TOOLS_ENABLED=true
export EXTERNAL_DNS_ENABLED=true

# Gateways
export GLOO_EDGE_ENABLED=true
