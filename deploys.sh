#!/usr/bin/env bash
###############################################################################
# deploys.sh
#
# Combining functions that build on basic "install" functions.
###############################################################################
function deploy_istio_sidecar {
  local _cluster
  _cluster=$1

  create_namespace "$_cluster" istio-system
#  install_istio_secrets "$_cluster" "$_cluster" istio-system
  install_istio_sidecar -c "$_cluster"
  install_kgateway_crds "$_cluster"
}

function deploy_istio_ambient {
  local _cluster
  _cluster=$1

  create_namespace "$_cluster" istio-system
  install_istio_secrets "$_cluster" "$_cluster" istio-system
  install_istio_ambient -c "$_cluster"
  install_kgateway_crds "$_cluster"
}

function deploy_kgateway_eastwest {
  local _cluster 
  _cluster=$1

  create_namespace "$_cluster" istio-eastwest
  install_kgateway_eastwest "$_cluster" "$_cluster"
}

function deploy_gme_server {
  local _cluster
  _cluster=$1

  install_gloo_mgmt_server -c "$_cluster"
}

function deploy_gme_agent {
  local _cluster _mgmt_context
  _cluster=$1
  _mgmt_context=$2

  install_gloo_agent "$_cluster" "$_cluster" "$_mgmt_context"
  install_gloo_k8s_cluster "$_cluster" "$_mgmt_context"
}

function deploy_ambient_kgateway_helloworld {
  local _cluster _east_west
  _cluster=${1:-cluster1}
  _east_west=${2:-false}
  
  deploy_istio_ambient "$_cluster"
  "$_east_west" && deploy_kgateway_eastwest "$_cluster"

  install_helloworld_app -x "$_cluster" -a

  create_namespace "$_cluster" istio-gateways
  install_kgateway_ingress_gateway "$_cluster" ingress-gateway istio-gateways 80
  install_kgateway_httproute "$_cluster" ingress-gateway istio-gateways helloworld helloworld 8001
  install_kgateway_reference_grant "$_cluster" istio-gateways helloworld helloworld

}

function deploy_argocd {
  local _cluster
  _cluster=${1:-argocd}

  create_namespace "$_cluster" argocd
  install_tls_cert_sercret -n argocd -c "$_cluster" -s argocd-server-tls  
  install_argocd -c "$_cluster"
}
