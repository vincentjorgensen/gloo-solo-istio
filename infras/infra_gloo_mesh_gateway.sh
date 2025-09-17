#!/usr/bin/env bash
# Clusters, single cluster, MGMT is same as workload
export GSI_MGMT_CLUSTER=cluster1
export GSI_MGMT_CONTEXT=cluster1
export GSI_MGMT_NETWORK=cluster1
export GSI_CLUSTER=cluster1
export GSI_CONTEXT=cluster1
export GSI_NETWORK=cluster1

# Infrastructure
export GME_ENABLED=true       # Required for Gloo-Mesh-Gateway
export SIDECAR_ENABLED=true   # Required for Gloo-Mesh-Gateway, could also be ambient?

# Testing Apps
export HELLOWORLD_ENABLED=true
export HTTPBIN_ENABLED=true
export CURL_ENABLED=true
export TOOLS_ENABLED=true
export EXTERNAL_DNS_ENABLED=true

# Gateways
export GLOO_MESH_GATEWAY_ENABLED=true
