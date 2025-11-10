#!/usr/bin/env bash
export GSI_CLUSTER=cluster2
export GSI_CONTEXT=$GSI_CLUSTER
export GSI_NETWORK=$GSI_CLUSTER

#Infrastructure
export GLOOUI_ENABLED=true
export GATEWAY_API_EXP_CRDS_ENABLED=true
export AMBIENT_ENABLED=true

# Test Apps
export HELLOWORLD_ENABLED=true
export NETSHOOT_ENABLED=true

# Gateway
export GLOO_GATEWAY_V1_ENABLED=true
