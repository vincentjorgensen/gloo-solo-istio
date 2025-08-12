#!/usr/bin/env bash
export GSI_CLUSTER=cluster1
export GSI_CONTEXT=cluster1
export GSI_NETWORK=cluster1
export TRUST_DOMAIN=cluster1.local

export GSI_REMOTE_CLUSTER=cluster2
export GSI_REMOTE_CONTEXT=cluster2
export GSI_REMOTE_NETWORK=cluster2
export REMOTE_TRUST_DOMAIN=cluster2.local

export AMBIENT_ENABLED=true
export EXTERNAL_DNS_ENABLED=true
export GLOO_GATEWAY_V2_ENABLED=true
export MULTICLUSTER_ENABLED=true
export SPIRE_ENABLED=true

export HELLOWORLD_ENABLED=true
export CURL_ENABLED=true
export TOOLS_ENABLED=true
export HTTPBIN_ENABLED=true
