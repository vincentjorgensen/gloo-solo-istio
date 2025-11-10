#!/usr/bin/env bash
# Clusters
export GSI_CLUSTER=cluster1
export GSI_CONTEXT=$GSI_CLUSTER
export GSI_NETWORK=$GSI_CLUSTER

# Testing Apps
export HELLOWORLD_ENABLED=true
export HTTPBIN_ENABLED=true
export NETSHOOT_ENABLED=true

# Gateways
export GLOO_GATEWAY_V1_ENABLED=true
