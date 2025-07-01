#!/usr/bin/env bash
###############################################################################
# decks.sh
# Part of GSI
###############################################################################
function deck_istio_sidecar {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_SIDECAR_ENABLED=enabled
  export GSI_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio_sidecar exec_telemetry_defaults exec_kgateway_crds exec_helloworld_app)
}

function deck_istio_mc_sidecar {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_SIDECAR_ENABLED=enabled
  export GSI_EW_SIZE=1
  export GSI_APP_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio_sidecar exec_telemetry_defaults exec_kgateway_crds exec_istio_eastwest exec_helloworld_app)
}

function deck_istio_ambient {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_AMBIENT_ENABLED=enabled
  export GSI_APP_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio_ambient exec_telemetry_defaults exec_kgateway_crds exec_helloworld_app)
}

function deck_istio_mc_ambient {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_NETWORK=$3
  export GSI_AMBIENT_ENABLED=enabled
  export GSI_EW_SIZE=1
  export GSI_APP_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio_ambient exec_telemetry_defaults exec_kgateway_crds exec_kgateway_eastwest exec_helloworld_app)
}

function deck_istio_oss_eastwest_link {
  export GSI_CLUSTER1=$1
  export GSI_CONTEXT1=$2
  export GSI_CONTEXT2=$3
  export GSI_DECK=(exec_oss_istio_remote_secrets)
}
function deck_kgateway_eastwest_link {
  export GSI_CONTEXT1=$1
  export GSI_CLUSTER1=$2
  export GSI_NETWORK1=$3
  export GSI_CONTEXT2=$4
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
  export GSI_DECK=(exec_gloo_virtual_destination exec_gloo_route_table exec_gloo_virtual_gateway)
}

function deck_gme_ingress_gateway {
  export GSI_CONTEXT=$1
  export GSI_NETWORK=$2
  export GSI_INGRESS_SIZE=1
  export GSI_DECK=(exec_istio_ingressgateway)
}