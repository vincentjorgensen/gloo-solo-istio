#!/usr/bin/env bash
###############################################################################
# globals.sh
# 
# functions for setting global state
###############################################################################
#-------------------------------------------------------------------------------
# Global versions of Helm Repos, Istio Repos, and Istio settings
#-------------------------------------------------------------------------------
export REVISION GME_SECRET_TOKEN TLDN MESH_ID
export ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR ISTIO_DISTRO ISTIO_126_FLAG
export GSI_MODE

export GME_FLAG AZURE_FLAG AWS_FLAG GME_MGMT_AGENT_FLAG
export SIDECAR_FLAG AMBIENT_FLAG CERT_MANAGER_FLAG

export DRY_RUN=""

# Cloud Providers
export DOCKER_DESKTOP_ENABLED="${DOCKER_DESKTOP_ENABLED:-true}"
export AWS_ENABLED="${AWS_ENABLED:-false}"
export AZURE_ENABLED="${AZURE_ENABLED:-false}"

# Namespaces
export ARGOCD_NAMESPACE=argocd
export GLOO_MESH_NAMESPACE=gloo-mesh
export KGATEWAY_SYSTEM_NAMESPACE=kgateway-system
export ISTIO_SYSTEM_NAMESPACE=istio-system
export KUBE_SYSTEM_NAMESPACE=kube-system
export AMBIENT_NAMESPACE=$ISTIO_SYSTEM_NAMESPACE
export SIDECAR_NAMESPACE=$ISTIO_SYSTEM_NAMESPACE

# Ingress
export INGRESS_NAMESPACE=ingress-gateways
export HTTP_INGRESS_PORT=80
export HTTPS_INGRESS_PORT=443
export INGRESS_GATEWAY_NAME=ingress-gateway

# Eastwest
export EASTWEST_NAMESPACE=eastwest-gateways
export EASTWEST_GATEWAY_NAME=eastwest-gateway
export MULTICLUSTER_NAMESPACE=$EASTWEST_NAMESPACE

# Testing Apps
export HELLOWORLD_NAMESPACE=helloworld
export HELLOWORLD_SERVICE_NAME=helloworld
export HELLOWORLD_SERVICE_PORT=8001
export CURL_NAMESPACE=curl
export TOOLS_NAMESPACE=tools

# Cert manager
export CERT_MANAGER_ENABLED="${CERT_MANAGER_ENABLED:-false}"
export CERT_MANAGER_VER="v1.18.2"
export CERT_MANAGER_NAMESPACE="cert-manager"
export CERT_MANAGER_INGRESS_SECRET="ingress-ca-key-pair"

# Spire
export SPIRE_ENABLED="${SPIER_ENABLED:-false}"
export SPIRE_NAMESPACE=spire-server
export SPIRE_CRDS_VER=0.5.0
export SPIRE_SERVER_VER=0.24.2
export SPIRE_SECRET=spiffe-upstream-ca

# KGateway
export KGATEWAY_ENABLED="${KGATEWAY_ENABLED:-false}"
export KGATEWAY_NAMESPACE=$KGATEWAY_SYSTEM_NAMESPACE
export KGATEWAY_VER=v1.2.1
export KGATEWAY_EXPERIMENTAL_VER=v1.3.0
export KGATEWAY_CRDS_HELM_REPO=oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds
export KGATEWAY_HELM_REPO=oci://cr.kgateway.dev/kgateway-dev/charts/kgateway
export KGATEWAY_HELM_VER=v2.0.3

# Gloo Gateway V2
export GLOO_GATEWAY_V2_ENABLED="${GLOO_GATEWAY_V2_ENABLED:-false}"
export GLOO_GATEWAY_V2_CRDS_HELM_REPO=oci://us-docker.pkg.dev/developers-369321/gloo-gateway-public-nonprod/charts/gloo-gateway-crds
export GLOO_GATEWAY_V2_HELM_REPO=oci://us-docker.pkg.dev/developers-369321/gloo-gateway-public-nonprod/charts/gloo-gateway
export GLOO_GATEWAY_V2_HELM_VER=2.0.0-alpha.2
export GLOO_GATEWAY_V2_NAMESPACE=gloo-gateway-system

# Istio repo versions
export HELM_REPO_123=oci://us-docker.pkg.dev/gloo-mesh/istio-helm-207627c16668
export ISTIO_REPO_123=us-docker.pkg.dev/gloo-mesh/istio-207627c16668
export ISTIO_VER_123=1.23.4
export HELM_REPO_124=oci://us-docker.pkg.dev/gloo-mesh/istio-helm-4d37697f9711
export ISTIO_REPO_124=us-docker.pkg.dev/gloo-mesh/istio-4d37697f9711
export ISTIO_VER_124=1.24.5
export HELM_REPO_125=oci://us-docker.pkg.dev/soloio-img/istio-helm
export ISTIO_REPO_125=us-docker.pkg.dev/soloio-img/istio
export ISTIO_VER_125=1.25.3
export HELM_REPO_126=oci://us-docker.pkg.dev/soloio-img/istio-helm
export ISTIO_REPO_126=us-docker.pkg.dev/soloio-img/istio
export ISTIO_VER_126=1.26.2
export ISTIO_SECRET=cacerts

# Dataplane Modes
export AMBIENT_ENABLED="${AMBIENT_ENABLED:-false}"
export SIDECAR_ENABLED="${SIDECAR_ENABLED:-false}"

# GME
export GME_ENABLED="${GME_ENABLED:-false}"
export GME_VER_26="2.6.12"
export GME_VER_27="2.7.3"
export GME_VER_28="2.8.1"
export GME_VER_29="2.9.0"

export GME_GATEWAYS_WORKSPACE=gateways
export GME_APPLICATIONS_WORKSPACE=applications

export DEFAULT_GME="2.9"
export DEFAULT_GME_SECRET_TOKEN="my-lucky-secret-token"
export DEFAULT_MESH_ID="mesh"
export DEFAULT_TLDN=example.com
export DEFAULT_TRUST_DOMAIN="cluster.local"

export DEFAULT_GSI_MODE=create # create | delete

[[ -z "$GSI_MODE" ]] && export GSI_MODE=$DEFAULT_GSI_MODE
[[ -z "$GME_VERBOSE" ]] && export GME_VERBOSE=false

function set_gsi_mode {
  local _gsi_mode
  _gsi_mode=${1:-$DEFAULT_GSI_MODE}

  export GSI_MODE=$_gsi_mode
}

function enable_gme {
 export GME_ENABLED=true 
}

function disable_gme {
 export GME_ENABLED=false 
}

function set_revision {
  local _revision
  _revision=$1

  export REVISION="$_revision"
}

function set_istio {
  local _istio _flavor _distro
  _istio=$1
  _flavor=$2
  _variant=$3

  export ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR ISTIO_DISTRO
  ISTIO_VER=$(eval echo \$ISTIO_VER_"${_istio//.}")
  ISTIO_REPO=$(eval echo \$ISTIO_REPO_"${_istio//.}")
  HELM_REPO=$(eval echo \$HELM_REPO_"${_istio//.}")
  [[ -n $_flavor ]] && ISTIO_FLAVOR="-${_flavor}"
  [[ -n $_variant ]] && ISTIO_DISTRO="${_variant}"

  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 26 ]]; then
    ISTIO_126_FLAG="enabled"
  fi
}

function set_gme {
  local _gme
  _gme=$1

  export GME_VER
  GME_VER=$(eval echo \$GME_VER_"${_gme//.}")
}

function set_trust_domain {
  local _trust_domain
  _trust_domain=${1:-$DEFAULT_TRUST_DOMAIN}

  export TRUST_DOMAIN="$_trust_domain"
}

function set_mesh_id {
  local _mesh_id
  _mesh_id=${1:-$DEFAULT_MESH_ID}

  export MESH_ID="$_mesh_id"
}

function set_gme_secret_token {
  local _gme_secret_token
  _gme_secret_token=${1:-$DEFAULT_GME_SECRET_TOKEN}

  export GME_SECRET_TOKEN="$_gme_secret_token"
}

function set_tldn {
  local _tldn
  _tldn=${1:-$DEFAULT_TLDN}

  export TLDN="$_tldn"
}

function set_oss_defaults {
  set_revision main
  set_istio 1.26 solo distroless
  set_trust_domain $DEFAULT_TRUST_DOMAIN
  set_mesh_id $DEFAULT_MESH_ID
  set_gme_secret_token $DEFAULT_GME_SECRET_TOKEN
  set_tldn $DEFAULT_TLDN
}

function set_gme_defaults {
  set_oss_defaults
  enable_gme
  set_gme $DEFAULT_GME
}

function set_defaults {
  set_oss_defaults
}
# END
