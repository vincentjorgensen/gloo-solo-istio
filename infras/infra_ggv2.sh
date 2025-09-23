#!/usr/bin/env bash
export GSI_CLUSTER=cluster3
export GSI_CONTEXT=cluster3
export GSI_NETWORK=cluster3

#Infrastructure

# Test Apps
export HELLOWORLD_ENABLED=true
export HTTPBIN_ENABLED=true
export CURL_ENABLED=true
export NETSHOOT_ENABLED=true

# Gateway
export GLOO_GATEWAY_V2_ENABLED=true
