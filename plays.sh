#!/usr/bin/env bash
###############################################################################
# plays.sh
# Part of GSI
###############################################################################
function play_ambient_multicluster {
  local _cluster1 _clusster2
  _cluster1=$1
  _cluster2=$2

  export AMBIENT_ENABLED=true
  export SIDECAR_ENABLED=false

  create_namespace "$_cluster1" "$ISTIO_SYSTEM_NAMESPACE"
  create_namespace "$_cluster1" "$EASTWEST_NAMESPACE"
  create_namespace "$_cluster1" "$INGRESS_NAMESPACE"

  create_namespace "$_cluster2" "$ISTIO_SYSTEM_NAMESPACE"
  create_namespace "$_cluster2" "$EASTWEST_NAMESPACE"

  export GSI_SERVICE_VERSION=v1
  deck_istio_mc_ambient "$_cluster1" "$_cluster1" "$_cluster1"
  play_gsi

  export GSI_SERVICE_VERSION=v2
  deck_istio_mc_ambient "$_cluster2" "$_cluster2" "$_cluster2"
  play_gsi

  deck_kgateway_eastwest_link "$_cluster1" "$_cluster1" "$_cluster1" "$_cluster2"
  play_gsi

  deck_kgateway_eastwest_link "$_cluster2" "$_cluster2" "$_cluster2" "$_cluster1"
  play_gsi

  deck_kgateway_ingress_gateway "$_cluster1" "$HELLOWORLD_NAMESPACE" "$HELLOWORLD_SERVICE_NAME" "$HELLOWORLD_SERVICE_PORT"
  play_gsi
}

function play_sidecar_oss_multicluster {
  local _cluster1 _clusster2
  _cluster1=$1
  _cluster2=$2

  set_defaults
  export AMBIENT_ENABLED=false
  export SIDECAR_ENABLED=true

  create_namespace "$_cluster1" "$ISTIO_SYSTEM_NAMESPACE"
  create_namespace "$_cluster1" "$EASTWEST_NAMESPACE"
  create_namespace "$_cluster1" "$INGRESS_NAMESPACE"

  create_namespace "$_cluster2" "$ISTIO_SYSTEM_NAMESPACE"
  create_namespace "$_cluster2" "$EASTWEST_NAMESPACE"

  export GSI_SERVICE_VERSION=v1
  deck_istio_mc_sidecar "$_cluster1" "$_cluster1" "$_cluster1"
  play_gsi

  export GSI_SERVICE_VERSION=v2
  deck_istio_mc_sidecar "$_cluster2" "$_cluster2" "$_cluster2"
  play_gsi

  deck_istio_oss_eastwest_link "$_cluster1" "$_cluster1" "$_cluster2"
  play_gsi

  deck_istio_oss_eastwest_link "$_cluster2" "$_cluster2" "$_cluster1"
  play_gsi

  deck_istio_ingress_gateway  "$_cluster1" "$_cluster1" "$HELLOWORLD_NAMESPACE" "$HELLOWORLD_SERVICE_NAME" "$HELLOWORLD_SERVICE_PORT" 
  play_gsi
}

function play_sidecar_gme_multicluster {
  local _mgmt _cluster1 _clusster2
  _mgmt=${1:-mgmt}
  _cluster1=${2:-cluster1}
  _cluster2=${3:-cluster2}

  set_gme_defaults
  export AMBIENT_ENABLED=false
  export SIDECAR_ENABLED=true

  create_namespace "$_mgmt" gloo-mesh
  create_namespace "$_mgmt" gateways-config
  create_namespace "$_mgmt" applications-config

  create_namespace "$_cluster1" gloo-mesh
  create_namespace "$_cluster1" istio-system
  create_namespace "$_cluster1" istio-eastwest
  create_namespace "$_cluster1" istio-gateways

  create_namespace "$_cluster2" gloo-mesh
  create_namespace "$_cluster2" istio-system
  create_namespace "$_cluster2" istio-eastwest

  deck_gloo_mgmt_server "$_mgmt"
  play_gsi

  deck_gloo_agent "$_cluster1" "$_cluster1"
  play_gsi

  deck_gloo_agent "$_cluster2" "$_cluster2"
  play_gsi

  export GSI_SERVICE_VERSION=v1
  deck_istio_mc_sidecar "$_cluster1" "$_cluster1" "$_cluster1"
  play_gsi

  export GSI_SERVICE_VERSION=v2
  deck_istio_mc_sidecar "$_cluster2" "$_cluster2" "$_cluster2"
  play_gsi

  deck_gme_ingress_gateway "$_cluster1" "$_cluster1" 
  play_gsi
  
  export GSI_WORKSPACE_NAMESPACES=("$EASTWEST_NAMESPACE" "$INGRESS_NAMESPACE")
  export GSI_WORKSPACE_CLUSTERS=("$_cluster1" "$_cluster2")
  export GSI_WORKSPACESETTTINGS_IMPORT_WORKSPACES=("$GME_APPLICATIONS_WORKSPACE")
  export GSI_WORKSPACESETTTINGS_EXPORT_WORKSPACES=("*")
  deck_gloo_workspace "$GME_GATEWAYS_WORKSPACE"
  play_gsi

  export GSI_WORKSPACE_NAMESPACES=("$HELLOWORLD_NAMESPACE")
  export GSI_WORKSPACE_CLUSTERS=("$_cluster1" "$_cluster2")
  export GSI_WORKSPACESETTTINGS_IMPORT_WORKSPACES=("$GME_GATEWAYS_WORKSPACE")
  export GSI_WORKSPACESETTTINGS_EXPORT_WORKSPACES=("$GME_GATEWAYS_WORKSPACE")
  deck_gloo_workspace "$GME_APPLICATIONS_WORKSPACE"
  play_gsi

  deck_gloo_virtual_service "$GME_APPLICATIONS_WORKSPACE" "$HELLOWORLD_SERVICE_NAME" "$HELLOWORLD_SERVICE_PORT" "$_cluster1"
  play_gsi
}

function play_ambient_spire_istiogateway {
  local _cluster
  _cluster=${1:-cluster1}

  set_defaults
  export AMBIENT_ENABLED=true
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=true
  export MULTICLUSTER_ENABLED=false

  create_namespace "$_cluster" "$SPIRE_SERVER_NAMESPACE"
  create_namespace "$_cluster" "$ISTIO_SYSTEM_NAMESPACE"
  create_namespace "$_cluster" "$INGRESS_NAMESPACE"

  deck_ambient_spire "$_cluster" "$_cluster" "$_cluster"
  play_gsi

  deck_istio_ingressgateway_no_helm "$_cluster" "$HELLOWORLD_NAMESPACE" "$HELLOWORLD_SERVICE_NAME" "$HELLOWORLD_SERVICE_PORT"
  play_gsi
}

function play_ambient_kgateway {
  local _cluster
  _cluster=${1:-cluster1}

  export AMBIENT_ENABLED=true
  export SIDECAR_ENABLED=false
  export SPIRE_ENABLED=false
  export MULTICLUSTER_ENABLED=false

  create_namespace "$_cluster" "$KGATEWAY_SYSTEM_NAMESPACE"
  create_namespace "$_cluster" "$ISTIO_SYSTEM_NAMESPACE"
  create_namespace "$_cluster" "$INGRESS_NAMESPACE"

  export GSI_SERVICE_VERSION=v1
  deck_ambient "$_cluster" "$_cluster" "$_cluster"
  play_gsi

  deck_kgateway "$_cluster" "$HELLOWORLD_NAMESPACE" "$HELLOWORLD_SERVICE_NAME" "$HELLOWORLD_SERVICE_PORT"
  play_gsi
}

function play_spire_ambient_kgateway {
  local _cluster
  _cluster=${1:-cluster1}

  deck_spire_ambient_kgateway "$_cluster"
  play_gsi
}

function play_ambient_kgateway {
  local _cluster
  _cluster=${1:-cluster1}

  deck_ambient_kgateway "$_cluster"
  play_gsi
}

function play_mc_ambient_kgateway {
  local _cluster
  _cluster1=${1:-cluster1}
  _cluster2=${2:-cluster2}

  deck_mc_ambient_kgateway "$_cluster1" "$_cluster2"
#  play_gsi
}

function play_spire_ambient_istiogateway {
  local _cluster
  _cluster=${1:-cluster1}

  deck_spire_ambient_istiogateway "$_cluster"
  play_gsi
}

function play_mc_ambient_gloo_gateway_v2_cert_manager {
  local _cluster1 _cluster2
  _cluster1=${1:-cluster1}
  _cluster2=${2:-cluster2}

  deck_mc_ambient_gloo_gateway_v2_cert_manager "$_cluster1" "$_cluster2"
#  play_gsi
}

function play_ambient_kgateway_cert_manager {
  local _cluster
  _cluster=${1:-cluster1}

  deck_ambient_kgateway_cert_manager "$_cluster"
#  play_gsi
}

function play_ambient_istiogateway {
  local _cluster
  _cluster=${1:-cluster1}

  deck_ambient_istiogateway "$_cluster"
#  play_gsi
}

function play_ambient_gloo_gateway_v2_cert_manager {
  local _cluster
  _cluster=${1:-cluster1}

  deck_ambient_gloo_gateway_v2_cert_manager "$_cluster"
  play_gsi
}

function play_gloo_gateway_v2_cert_manager {
  local _cluster
  _cluster=${1:-cluster1}

  deck_gloo_gateway_v2_cert_manager "$_cluster"
  play_gsi
}