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
  export GSI_DECK=(exec_spire_secrets exec_spire_crds exec_spire_server exec_istio_secrets exec_istio exec_telemetry_defaults exec_k8s_gateway_crds exec_helloworld_app)
}

function deck_istio_ingressgateway_no_helm {
  export GSI_CONTEXT=$1
  export GSI_APP_SERVICE_NAMESPACE=$2
  export GSI_APP_SERVICE_NAME=$3
  export GSI_APP_SERVICE_PORT=$4
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_external_dns_for_pihole exec_istio_ingressgateway_no_helm exec_httproute exec_reference_grant)
}

function deck_kgateway_ingressgateway_no_helm {
  export GSI_CONTEXT=$1
  export GSI_APP_SERVICE_NAMESPACE=$2
  export GSI_APP_SERVICE_NAME=$3
  export GSI_APP_SERVICE_PORT=$4
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_kgateway_ingressgateway_no_helm exec_httproute exec_reference_grant)
}

function deck_kgateway {
  export GSI_CONTEXT=$1
  export GSI_APP_SERVICE_NAMESPACE=$2
  export GSI_APP_SERVICE_NAME=$3
  export GSI_APP_SERVICE_PORT=$4
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_k8s_gateway_crds exec_kgateway_crds exec_kgateway exec_kgateway_ingressgateway exec_httproute exec_reference_grant)
}