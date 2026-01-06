#!/usr/bin/env bash
export GSI_CLUSTER=cluster1
export GSI_CONTEXT=$GSI_CLUSTER
export GSI_NETWORK=$GSI_CLUSTER

#Infrastructure
export VAULT_ENABLED=true

# Test Apps
export HELLOWORLD_ENABLED=true
export NETSHOOT_ENABLED=true

# Gateway
