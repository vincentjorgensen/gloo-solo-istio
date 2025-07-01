#!/usr/bin/env bash
###############################################################################
# plays.sh
# Part of GSI
###############################################################################
function play_ambient_multicluster {
  local _cluster1 _clusster2
  _cluster1=$1
  _cluster2=$2

  set_defaults
  export AMBIENT_ENABLED=true
  export SIDECAR_ENABLED=false

  create_namespace "$_cluster1" istio-system
  create_namespace "$_cluster1" istio-eastwest
  create_namespace "$_cluster1" istio-gateways

  create_namespace "$_cluster2" istio-system
  create_namespace "$_cluster2" istio-eastwest

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

  create_namespace "$_cluster1" istio-system
  create_namespace "$_cluster1" istio-eastwest
  create_namespace "$_cluster1" istio-gateways

  create_namespace "$_cluster2" istio-system
  create_namespace "$_cluster2" istio-eastwest

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

  deck_gme_istio_ingress_gateway "$_cluster1" "$_cluster1" 
  
  export GSI_WORKSPACE_NAMESPACES=("$ISTIO_EASTWEST_NAMESPACE" "$ISTIO_GATEWAYS_NAMESPACE")
  export GSI_WORKSPACE_CLUSTERS=("$_cluster1" "$_cluster2")
  export GSI_WORKSPACESETTTINGS_IMPORT_WORKSPACES=("$GME_APPLICATIONS_WORKSPACE")
  export GSI_WORKSPACESETTTINGS_EXPORT_WORKSPACES=("*")
  deck_gloo_workspace "$GME_GATEWAYS_WORKSPACE"

  export GSI_WORKSPACE_NAMESPACES=("$HELLOWORLD_NAMESPACE")
  export GSI_WORKSPACE_CLUSTERS=("$_cluster1" "$_cluster2")
  export GSI_WORKSPACESETTTINGS_IMPORT_WORKSPACES=("$GME_GATEWAYS_WORKSPACE")
  export GSI_WORKSPACESETTTINGS_EXPORT_WORKSPACES=("$GME_GATEWAYS_WORKSPACE")
  deck_gloo_workspace "$GME_APPLICATIONS_WORKSPACE"

  deck_gloo_virtual_service "$HELLOWORLD_SERVICE_NAME" "$HELLOWORLD_SERVICE_PORT"
}