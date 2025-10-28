#!/usr/bin/env bash
export GSI_CLUSTER=cluster1
export GSI_CONTEXT=$GSI_CLUSTER
export GSI_NETWORK=$GSI_CLUSTER

#Infrastructure

# Test Apps
export NETSHOOT_ENABLED=true

# Gateway
export GLOO_GATEWAY_V2_ENABLED=true
