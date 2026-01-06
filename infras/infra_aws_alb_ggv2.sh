#!/usr/bin/env bash
export GSI_CLUSTER=alb-us-west-2
export GSI_CONTEXT=$GSI_CLUSTER
export GSI_NETWORK=$GSI_CLUSTER

#Infrastructure
export AWS_ENABLED=true
export AMBIENT_ENABLED=true
export CERT_MANAGER_ENABLED=true

# Test Apps
export HELLOWORLD_ENABLED=true
export NETSHOOT_ENABLED=true

# Gateway
export GLOO_GATEWAY_V2_ENABLED=true
