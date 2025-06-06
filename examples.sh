#!/usr/bin/env bash

source "$(dirname "$0")"/functions.sh

istio_ambient_kgateway_eastwest_helloworld() {
  local _cluster1 _cluster2 _istio
  _cluster1=$1
  _cluster2=$2
  _istio=1.26

  set_revision main

  deploy_istio_ambient "$_cluster1" "$_istio"
  install_kgateway_crds "$_cluster1"
  deploy_kgateway_eastwest "$_cluster1"

  deploy_istio_ambient "$_cluster2" "$_istio"
  install_kgateway_crds "$_cluster2"
  deploy_kgateway_eastwest "$_cluster2"

  install_kgateway_ew_link "$_cluster1" "$_cluster1" "$_cluster1" "$_cluster2"
  install_kgateway_ew_link "$_cluster2" "$_cluster2" "$_cluster2" "$_cluster1"

  install_helloworld_app -x "$_cluster1" -a
  install_helloworld_app -x "$_cluster2" -a

  create_namespace "$_cluster1" "$_cluster1" istio-gateways
  install_kgateway_ingress_gateway "$_cluster1" ingress-gateway istio-gateways '*.example.com' 80
  install_kgateway_httproute "$_cluster1" ingress-gateway istio-gateways helloworld helloworld 8001 helloworld.example.com
  install_kgateway_reference_grant "$_cluster1" istio-gateways helloworld helloworld

  install_kgateway_ingress_gateway "$_cluster1" helloworld-gateway helloworld 'helloworld.example.com' 80
  install_kgateway_httproute "$_cluster1" helloworld-gateway helloworld helloworld helloworld 8001 helloworld.example.com
#  install_kgateway_reference_grant "$_cluster1" istio-gateways helloworld helloworld
}
