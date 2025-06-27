#!/usr/bin/env bash

ambient_and_kgateway() {
  local _cluster1
  _cluster1=$1

  set_defaults

  deploy_istio_ambient "$_cluster1"

  install_curl_app -x "$_cluster1" -a
}

ambient_kgateway_helloworld() {
  local _cluster
  _cluster=$1

  set_defaults
  install_external_dns_for_pihole "$_cluster"

  deploy_ambient_kgateway_helloworld "$_cluster" false
}

ambient_kgateway_eastwest_helloworld() {
  local _cluster1 _cluster2
  _cluster1=$1
  _cluster2=$2

  set_defaults
  install_external_dns_for_pihole "$_cluster1"

  deploy_istio_ambient "$_cluster1"
  deploy_kgateway_eastwest "$_cluster1"

  deploy_istio_ambient "$_cluster2"
  deploy_kgateway_eastwest "$_cluster2"

  install_kgateway_ew_link "$_cluster1" "$_cluster1" "$_cluster1" "$_cluster2"
  install_kgateway_ew_link "$_cluster2" "$_cluster2" "$_cluster2" "$_cluster1"

  install_helloworld_app -x "$_cluster1" -a -v v1
  install_helloworld_app -x "$_cluster2" -a -v v2

  create_namespace "$_cluster1" istio-gateways
  install_kgateway_ingress_gateway "$_cluster1" ingress-gateway istio-gateways 80
  install_kgateway_httproute "$_cluster1" ingress-gateway istio-gateways helloworld helloworld 8001
  install_kgateway_reference_grant "$_cluster1" istio-gateways helloworld helloworld
}

sidecar_istio_gateway_helloworld() {
  local _cluster
  _cluster=$1

  set_defaults
  install_external_dns_for_pihole "$_cluster"

  deploy_istio_sidecar "$_cluster"

  install_helloworld_app -x "$_cluster" -i -v v1

  install_istio_ingressgateway "$_cluster" "$_cluster" 1

  install_istio_vs_and_gateway "$_cluster" helloworld helloworld helloworld 8001
}

istio_sidecar_istio_eastwest_helloworld() {
  local _cluster1 _cluster2
  _cluster1=$1
  _cluster2=$2

  set_defaults
  #install_external_dns_for_pihole "$_cluster1"

  deploy_istio_sidecar "$_cluster1"
  install_istio_eastwestgateway -x "$_cluster1"

  deploy_istio_sidecar "$_cluster2"
  install_istio_eastwestgateway -x "$_cluster2"

  install_mutual_remote_secrets "$_cluster1" "$_cluster2"

  install_helloworld_app -x "$_cluster1" -i -v v1
  install_helloworld_app -x "$_cluster2" -i -v v2

  install_istio_ingressgateway "$_cluster1" "$_cluster1" 1

  install_istio_vs_and_gateway "$_cluster1" helloworld helloworld helloworld 8001
}

ex_gme_sidecar_multicluster() {
  local _mgmt_ _cluster1 _cluster2
  _mgmt=${1:-mgmt}
  _cluster1=${2:-cluster1}
  _cluster2=${3:-cluster2}

  set_gme_defaults

  install_gloo_mgmt_server -c "$_mgmt"
  install_gloo_agent -c "$_cluster1" -m "$_mgmt"
  install_gloo_agent -c "$_cluster2" -m "$_mgmt"

  install_gloo_k8s_cluster "$_cluster1" "$_mgmt"
  install_gloo_k8s_cluster "$_cluster2" "$_mgmt"

  install_istio_base "$_mgmt"
  deploy_istio_sidecar "$_cluster1"
  deploy_istio_sidecar "$_cluster2"

  install_root_trust_policy "$_mgmt"

  install_istio_eastwestgateway -x "$_cluster1"
  install_istio_eastwestgateway -x "$_cluster2"

##  create_namespace "$_mgmt" istio-eastwest
##  create_namespace "$_mgmt" istio-gateways
##  create_namespace "$_mgmt" helloworld

  install_helloworld_app -x "$_cluster1" -i -v v1
  install_helloworld_app -x "$_cluster2" -i -v v2

  # Workspaces
  create_namespace "$_mgmt" gateways-config
  create_namespace "$_mgmt" applications-config
  install_gloo_workspace -m "$_mgmt" -n gateways -p istio-eastwest -p istio-gateways -r "$_cluster1" -r "$_cluster2"
  install_gloo_workspace -m "$_mgmt" -n applications -p helloworld -r "$_cluster1" -r "$_cluster2"

  # WorkspaceSettings
  install_gloo_workspacesettings -m "$_mgmt" -n gateways -i applications -e '*'
  install_gloo_workspacesettings -m "$_mgmt" -n applications -i gateways -e gateways

  # VirtualDestinations
  install_gloo_virtual_destination "$_mgmt" helloworld 8001

  # RouteTables
  install_gloo_route_table "$_mgmt" helloworld 

  install_istio_ingressgateway "$_cluster1" "$_cluster1" 1

  # Since GME is enabled, will route to the Virtual Destination
##  install_istio_vs_and_gateway "$_cluster1" helloworld helloworld helloworld 8080

  install_gloo_virtual_gateway "$_mgmt"

}
