#!/usr/bin/env bash
###############################################################################
# decks.sh
# Part of GSI
###############################################################################
function deck_istio {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio exec_telemetry_defaults exec_k8s_gateway_crds exec_helloworld_app)
}

function deck_istio_mc_sidecar {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_EW_SIZE=1
  export GSI_APP_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio exec_telemetry_defaults exec_k8s_gateway_crds exec_istio_eastwest exec_helloworld_app)
}

function deck_istio_mc_ambient {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_NETWORK=$3
  export GSI_EW_SIZE=1
  export GSI_APP_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio exec_telemetry_defaults exec_k8s_gateway_crds exec_kgateway_eastwest exec_helloworld_app)
}

function deck_istio_oss_eastwest_link {
  export GSI_CLUSTER_REMOTE=$1
  export GSI_CONTEXT_REMOTE=$2
  export GSI_CONTEXT_LOCAL=$3
  export GSI_DECK=(exec_oss_istio_remote_secrets)
}
function deck_kgateway_eastwest_link {
  export GSI_CONTEXT_REMOTE=$1
  export GSI_CLUSTER_REMOTE=$2
  export GSI_NETWORK_REMOTE=$3
  export GSI_CONTEXT_LOCAL=$4
  export GSI_DECK=(exec_kgateway_ew_link)
}

function deck_kgateway_ingress_gateway {
  export GSI_CONTEXT=$1
  export GSI_APP_SERVICE_NAMESPACE=$2
  export GSI_APP_SERVICE_NAME=$3
  export GSI_APP_SERVICE_PORT=$4
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_external_dns_for_pihole exec_kgateway_ingress_gateway exec_kgateway_httproute exec_kgateway_reference_grant)
}

function deck_istio_ingress_gateway {
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$2
  export GSI_APP_SERVICE_NAMESPACE=$3
  export GSI_APP_SERVICE_NAME=$4
  export GSI_APP_SERVICE_PORT=$5
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_istio_ingressgateway exec_istio_vs_and_gateway)
}

function deck_gloo_mgmt_server {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_DECK=(exec_gloo_mgmt_server exec_root_trust_policy exec_istio_base)
}

function deck_gloo_agent {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_DECK=(exec_gloo_agent exec_gloo_k8s_cluster)
}

function deck_gloo_workspace {
  export GSI_WORKSPACE_NAME=$1
  export GSI_DECK=(exec_gloo_workspace exec_gloo_workspacesettings)
}

function deck_gloo_virtual_service {
  export GSI_WORKSPACE_NAME=$1
  export GSI_APP_SERVICE_NAME=$2
  export GSI_APP_SERVICE_PORT=$3
  export GSI_GATEWAY_CLUSTER=$4
  export GSI_DECK=(exec_gloo_virtual_destination exec_gloo_route_table exec_gloo_virtual_gateway)
}

function deck_gme_ingress_gateway {
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$2
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_istio_ingressgateway)
}

function deck_ambient {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_NETWORK=$3
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_istio_secrets exec_istio exec_telemetry_defaults exec_helloworld_app)
}

function deck_ambient_spire {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_NETWORK=$3
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_spire_secrets exec_spire_crds exec_spire_server exec_istio_secrets exec_istio exec_telemetry_defaults exec_helloworld_app)
}

function deck_spire_ambient_kgateway {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1
  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_INGRESS_SIZE=1

  export AMBIENT_ENABLED=true
  export KGATEWAY_ENABLED=true
  export MULTICLUSTER_ENABLED=false
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=true

  gsi_init

  export GSI_DECK=(exec_create_namespaces
                   exec_spire_secrets exec_spire_crds exec_spire_server
                   exec_istio exec_telemetry_defaults
                   exec_k8s_gateway_crds exec_kgateway_crds exec_kgateway
                   exec_ingress_gateway_api
                   exec_helloworld_app exec_httproute exec_reference_grant)
}

function deck_spire_ambient_istiogateway {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1
  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_INGRESS_SIZE=1

  export AMBIENT_ENABLED=true
  export GATEWAY_CLASS_NAME=istio
  export ISTIOGATEWAY_ENABLED=true
  export KGATEWAY_ENABLED=false
  export MULTICLUSTER_ENABLED=false
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=true

  export GSI_DECK=(
                   exec_create_namespaces
                   exec_spire_secrets exec_spire_crds exec_spire_server
                   exec_istio exec_telemetry_defaults
                   exec_k8s_gateway_crds 
                   exec_ingress_gateway_api
                   exec_helloworld_app exec_httproute exec_reference_grant)
}

function deck_ambient_kgateway {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1
  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_INGRESS_SIZE=1

  export AMBIENT_ENABLED=true
  export GATEWAY_CLASS_NAME=kgateway
  export KGATEWAY_ENABLED=true
  export MULTICLUSTER_ENABLED=false
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=false

  gsi_init

  export GSI_DECK=(
    exec_create_namespaces
    exec_istio exec_telemetry_defaults
    exec_k8s_gateway_crds exec_kgateway_crds exec_kgateway
    exec_external_dns_for_pihole
    exec_ingress_gateway_api
    exec_helloworld_app exec_httproute exec_reference_grant
  )
}

function deck_mc_ambient_kgateway {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1
  export GSI_REMOTE_CLUSTER=$2
  export GSI_REMOTE_CONTEXT=$2
  export GSI_REMOTE_NETWORK=$2

  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_INGRESS_SIZE=1

  export AMBIENT_ENABLED=true
  export GATEWAY_CLASS_NAME=kgateway
  export EASTWEST_GATEWAY_CLASS_NAME=istio-eastwest
  export EASTWEST_REMOTE_GATEWAY_CLASS_NAME=istio-remote

  export KGATEWAY_ENABLED=true
  export MULTICLUSTER_ENABLED=true
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=false

  gsi_init

  export GSI_DECK=(
    exec_create_namespaces
    exec_istio_secrets
    exec_istio
    exec_telemetry_defaults
    exec_k8s_gateway_crds
    exec_eastwest_gateway_api
    exec_helloworld_app
    exec_curl_app

    exec_gsi_cluster_swap

    exec_create_namespaces
    exec_istio_secrets
    exec_istio
    exec_telemetry_defaults
    exec_k8s_gateway_crds
    exec_eastwest_gateway_api
    exec_helloworld_app

    exec_eastwest_link_gateway_api
    exec_gsi_cluster_swap
    exec_eastwest_link_gateway_api


    exec_kgateway_crds
    exec_kgateway
    exec_external_dns_for_pihole
    exec_ingress_gateway_api
    exec_httproute
    exec_reference_grant
  )
}

function deck_mc_ambient_gloo_gateway_v2_cert_manager {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1
  export GSI_REMOTE_CLUSTER=$2
  export GSI_REMOTE_CONTEXT=$2
  export GSI_REMOTE_NETWORK=$2

  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT

  export AMBIENT_ENABLED=true
  export CERT_MANAGER_ENABLED=true
  export GLOO_GATEWAY_V2_ENABLED=true
  export MULTICLUSTER_ENABLED=true

  gsi_init

  export GSI_DECK=(
    exec_create_namespaces
    exec_k8s_gateway_experimental_crds

    exec_istio_secrets
    exec_istio
    exec_telemetry_defaults
    exec_eastwest_gateway_api
    exec_helloworld_app
    exec_curl_app

    exec_gsi_cluster_swap

    exec_create_namespaces
    exec_k8s_gateway_experimental_crds

    exec_istio_secrets
    exec_istio
    exec_telemetry_defaults
    exec_eastwest_gateway_api
    exec_helloworld_app

    exec_eastwest_link_gateway_api
    exec_gsi_cluster_swap
    exec_eastwest_link_gateway_api

    exec_cert_manager
    exec_issuer_ingress_gateways

    exec_external_dns_for_pihole

    exec_gloo_gateway_v2_crds
    exec_gloo_gateway_v2
    exec_ingress_gateway_api
    exec_httproute
    exec_reference_grant
  )
}

function deck_kgateway {
  export GSI_CONTEXT=$1
  export GSI_APP_SERVICE_NAMESPACE=$2
  export GSI_APP_SERVICE_NAME=$3
  export GSI_APP_SERVICE_PORT=$4
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_k8s_gateway_crds exec_kgateway_crds exec_kgateway exec_kgateway_ingressgateway exec_httproute exec_reference_grant)
}

function deck_ambient_kgateway_cert_manager {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1

  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_INGRESS_SIZE=1

  export AMBIENT_ENABLED=true
  export GATEWAY_CLASS_NAME=kgateway
  export EASTWEST_GATEWAY_CLASS_NAME=istio-eastwest
  export EASTWEST_REMOTE_GATEWAY_CLASS_NAME=istio-remote

  export CERT_MANAGER_ENABLED=true
  export GLOO_GATEWAY_V2_ENABLED=false
  export KGATEWAY_ENABLED=true
  export MULTICLUSTER_ENABLED=false
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=false

  gsi_init

  export GSI_DECK=(
    exec_create_namespaces

    exec_cert_manager
    exec_cluster_issuer
    exec_issuer_ingress_gateways

    exec_istio_secrets
    exec_istio
    exec_telemetry_defaults
    exec_helloworld_app
    exec_curl_app

    exec_external_dns_for_pihole

    exec_k8s_gateway_crds
    exec_kgateway_crds
    exec_kgateway
    exec_ingress_gateway_api
    exec_httproute
    exec_reference_grant
  )
}

function deck_ambient_istiogateway {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1
  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_APP_GATEWAY_SECRET="${HELLOWORLD_SERVICE_NAME}-ca-key-pair"
  export GSI_INGRESS_SIZE=1

  export AMBIENT_ENABLED=true
  export CERT_MANAGER_ENABLED=true
  export GATEWAY_CLASS_NAME=istio
  export GLOO_GATEWAY_V2_ENABLED=false
  export ISTIOGATEWAY_ENABLED=true
  export KGATEWAY_ENABLED=false
  export MULTICLUSTER_ENABLED=false
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=false

  gsi_init

  export GSI_DECK=(
    exec_create_namespaces
                   
    exec_cert_manager
    exec_cluster_issuer

    exec_istio
    exec_telemetry_defaults
    exec_helloworld_app
    exec_curl_app

    exec_issuer_istio_ingress_gateway
    exec_istio_ingressgateway
    exec_istio_vs_and_gateway
  )
}

function deck_ambient_gloo_gateway_v2_cert_manager {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1

  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_INGRESS_SIZE=1

  export AMBIENT_ENABLED=true
  export CERT_MANAGER_ENABLED=true
  export GLOO_GATEWAY_V2_ENABLED=true

  gsi_init

  export GSI_DECK=(
    exec_create_namespaces

    exec_k8s_gateway_experimental_crds
    exec_cert_manager

    exec_issuer_ingress_gateways

    exec_istio
    exec_telemetry_defaults

    exec_helloworld_app
    exec_curl_app

    exec_external_dns_for_pihole

    exec_gloo_gateway_v2_crds
    exec_gloo_gateway_v2
    exec_ingress_gateway_api
    exec_httproute
    exec_reference_grant
  )
}

function deck_gloo_gateway_v2_cert_manager {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$1

  export GSI_APP_SERVICE_NAMESPACE=$HELLOWORLD_NAMESPACE
  export GSI_APP_SERVICE_NAME=$HELLOWORLD_SERVICE_NAME
  export GSI_APP_SERVICE_PORT=$HELLOWORLD_SERVICE_PORT
  export GSI_INGRESS_SIZE=1

  export CERT_MANAGER_ENABLED=true
  export GLOO_GATEWAY_V2_ENABLED=true

  gsi_init

  export GSI_DECK=(
    exec_create_namespaces

    exec_k8s_gateway_experimental_crds
    exec_cert_manager

    exec_issuer_ingress_gateways

    exec_helloworld_app
    exec_curl_app

    exec_external_dns_for_pihole

    exec_gloo_gateway_v2_crds
    exec_gloo_gateway_v2
    exec_ingress_gateway_api
    exec_httproute
    exec_reference_grant
  )
}
# END