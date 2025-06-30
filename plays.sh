#!/usr/bin/env bash


function play_ambient_multicluster {
  local _cluster1 _clusster2
  _cluster1=$1
  _cluster2=$2

  set_defaults

  create_namespace "$_cluster1" istio-system
  create_namespace "$_cluster1" istio-eastwest
  create_namespace "$_cluster1" istio-gateways

  create_namespace "$_cluster2" istio-system
  create_namespace "$_cluster2" istio-eastwest

  export GSI_SERVICE_VERSION=v1
  deck_istio_mc_ambient "$_cluster1" "$_cluster1"
  play_gsi

  export GSI_SERVICE_VERSION=v2
  deck_istio_mc_ambient "$_cluster2" "$_cluster2"
  play_gsi

  deck_kgateway_eastwest_link "$_cluster1" "$_cluster1" "$_cluster1" "$_cluster2"
  play_gsi

  deck_kgateway_eastwest_link "$_cluster2" "$_cluster2" "$_cluster2" "$_cluster1"
  play_gsi

  deck_kgateway_ingress_gateway "$_cluster1" "$HELLOWORLD_NAMESPACE" "$HELLOWORLD_SERVICE_NAME" "$HELLOWORLD_SERVICE_PORT"
  play_gsi
}

