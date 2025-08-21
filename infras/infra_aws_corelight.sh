#!/usr/bin/env bash
export GSI_CLUSTER=c1-us-west-2
export GSI_CONTEXT=c1-us-west-2
export GSI_NETWORK=c1-us-west-2
export AWS_REGION=us-west-2

export GSI_MGMT_CLUSTER=c1-us-west-2
export GSI_MGMT_CONTEXT=c1-us-west-2

export DOCKER_DESKTOP_ENABLED=false
export AWS_ENABLED=true

export GLOO_GATEWAY_V1_ENABLED=true
export GLOO_GATEWAY_V1_VER=1.19.4
export GATEWAY_API_ENABLED=true     # V1 but with Gateway API
export HTTPS_ENABLED=true
export INGRESS_SIZE=3

export GME_ENABLED=true
export GME_VER=2.9.2
export GME_GLOOUI_SERVICE_TYPE=ClusterIP

export TLDN=soloio.vincentjorgensen.com

export HELLOWORLD_ENABLED=true
export CURL_ENABLED=true
export UTILS_ENABLED=true
export NETSHOOT_ENABLED=true
export HTTPBIN_ENABLED=true
