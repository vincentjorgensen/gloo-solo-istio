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
  local _cluster1 _cluster2 _istio _revision
  _cluster1=$1
  _cluster2=$2

  set_defaults
  install_external_dns_for_pihole "$_cluster1"

  deploy_ambient_kgateway_helloworld "$_cluster1"
  deploy_ambient_kgateway_helloworld "$_cluster2"

  install_kgateway_ew_link "$_cluster1" "$_cluster1" "$_cluster1" "$_cluster2"
  install_kgateway_ew_link "$_cluster2" "$_cluster2" "$_cluster2" "$_cluster1"

  create_namespace "$_cluster1" istio-gateways
  install_kgateway_ingress_gateway "$_cluster1" ingress-gateway istio-gateways 80
  install_kgateway_httproute "$_cluster1" ingress-gateway istio-gateways helloworld helloworld 8001
  install_kgateway_reference_grant "$_cluster1" istio-gateways helloworld helloworld

#  install_kgateway_ingress_gateway "$_cluster1" helloworld-gateway helloworld 'helloworld.example.com' 80
#  install_kgateway_httproute "$_cluster1" helloworld-gateway helloworld helloworld helloworld 8001 helloworld.example.com
#  install_kgateway_reference_grant "$_cluster1" istio-gateways helloworld helloworld
}

sidecar_istio_gateway_helloworld() {
  local _cluster
  _cluster=$1

  set_defaults
  install_external_dns_for_pihole "$_cluster"

  deploy_istio_sidecar "$_cluster"

  install_helloworld_app -x "$_cluster" -i

  install_istio_ingressgateway "$_cluster" "$_cluster" 1

  install_istio_vs_and_gateway "$_cluster" helloworld helloworld helloworld 8001
}

istio_sidecar_istio_eastwest_helloworld() {
  local _cluster1 _cluster2 _istio _revision
  _cluster1=$1
  _cluster2=$2
  _istio=$3
  _revision=main

  set_defaults

  deploy_istio_sidecar "$_cluster1"
  install_istio_eastwestgateway "$_cluster1" "$_cluster1" 1

  deploy_istio_sidecar "$_cluster2"
  install_istio_eastwestgateway "$_cluster2" "$_cluster2" 1

  install_mutual_remote_secrets "$_cluster1" "$_cluster2"

  install_helloworld_app -x "$_cluster1" -i
  install_helloworld_app -x "$_cluster2" -i

  install_istio_ingressgateway "$_cluster1" "$_cluster1" 1

  install_istio_vs_and_gateway "$_cluster1" helloworld helloworld helloworld.example.com helloworld 8001
}
