#!/usr/bin/env bash
export GSI_CLUSTER=cluster1
export GSI_CONTEXT=$GSI_CLUSTER
export GSI_NETWORK=$GSI_CLUSTER

#Infrastructure
export GLOOUI_ENABLED=true
export EXTERNAL_DNS_ENABLED=true
export AMBIENT_ENABLED=true

# Test Apps
export HELLOWORLD_ENABLED=true
export NETSHOOT_ENABLED=true

# Gateway
export GLOO_GATEWAY_V2_ENABLED=true
