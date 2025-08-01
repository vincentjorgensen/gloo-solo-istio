#!/usr/bin/env bash
 ###############################################################################
# globals.sh
# 
# functions for setting global state
###############################################################################
#-------------------------------------------------------------------------------
# Global versions of Helm Repos, Istio Repos, and Istio settings
#-------------------------------------------------------------------------------
export TEMPLATES CERTS UTAG MANIFESTS CERT_MANAGER_CERTS SPIRE_CERTS
TEMPLATES="$(dirname "$0")"/templates
CERTS="$(dirname "$0")"/certs
SPIRE_CERTS="$(dirname "$0")"/spire-certs
CERT_MANAGER_CERTS="$(dirname "$0")"/cert-manager/certs

export REVISION GME_SECRET_TOKEN TLDN MESH_ID
export ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR ISTIO_DISTRO ISTIO_126_FLAG
export GSI_MODE
export EASTWEST_GATEWAY_CLASS_NAME EASTWEST_REMOTE_GATEWAY_CLASS_NAME

# Jinja2 flags
export GME_FLAG AZURE_FLAG AWS_FLAG GME_MGMT_AGENT_FLAG KGATEWAY_FLAG
export SIDECAR_FLAG AMBIENT_FLAG CERT_MANAGER_FLAG INGRESS_ENABLED EXTAUTH_FLAG
export GLOO_GATEWAY_V2_FLAG GATEWAY_CLASS_NAME SPIRE_FLAG MC_FLAG
export RATELIMITER_FLAG DOCKER_FLAG GCP_FLAG

# Testing and generating reproducible plans
export DRY_RUN=""

# Cloud Providers
export DOCKER_DESKTOP_ENABLED="${DOCKER_DESKTOP_ENABLED:-true}"
export AWS_ENABLED="${AWS_ENABLED:-false}"
export AZURE_ENABLED="${AZURE_ENABLED:-false}"
export GCP_ENABLED="${GCP_ENABLED:-false}"

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
export MULTICLUSTER_ENABLED=${MULTICLUSTER_ENABLED:-false}
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

export TRAFFIC_POLICY_NAME=oauth-authorization-code

export KEYCLOAK_ENABLED="${KEYCLOAK_ENABLED:-false}"
export KEYCLOAK_NAMESPACE=keycloak
export KEYCLOAK_VER=26.3

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

function is_create_mode {
  if [[ $GSI_MODE =~ (create|apply) ]]; then
    return 0
  else
    return 1
  fi
}

function gsi_init {
  # For reproducibilty and sharing, we save the manifests
  UTAG=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8)
  MANIFESTS="$(dirname "$0")"/manifests/$UTAG
  mkdir -p "$MANIFESTS"
  echo "export MANIFESTS=$MANIFESTS"

  # Gloo Mesh Enterprise (GME)
  $GME_ENABLED && GME_FLAG=enabled && echo '#' GME is enabled
  $GME_MGMT_AGENT_ENABLED && GME_MGMT_AGENT_FLAG=enabled

  # cloud / k8s providers
  $DOCKER_DESKTOP_ENABLED   && DOCKER_FLAG=enabled   && echo '#' Docker Desktop is enabled
  $AWS_ENABLED   && AWS_FLAG=enabled   && echo '#' AWS is enabled
  $AZURE_ENABLED && AZURE_FLAG=enabled && echo '#' AZURE is enabled
  $GCP_ENABLED && GCP_FLAG=enabled && echo '#' AZURE is enabled

  # Istio mesh mode
  $SIDECAR_ENABLED && SIDECAR_FLAG=enabled && echo '#' Istio Sidecar is enabled
  $AMBIENT_ENABLED && AMBIENT_FLAG=enabled && echo '#' Istio Ambient is enabled
  
  # Istio multicluster
  if $MULTICLUSTER_ENABLED; then
    MC_FLAG=enabled
    echo '#' Multicluster is enabled 
    if $AMBIENT_ENABLED; then
      EASTWEST_GATEWAY_CLASS_NAME=istio-eastwest
      EASTWEST_REMOTE_GATEWAY_CLASS_NAME=istio-remote
      echo '#' Ambient Multicluster is enabled 
    fi
  fi
  
  # Kgateway (OSS)
  if $KGATEWAY_ENABLED; then
    KGATEWAY_FLAG=enabled
    GATEWAY_CLASS_NAME=kgateway
    INGRESS_ENABLED=true
    echo '#' Kgateway is enabled 
  fi
  # Gloo Gateway V2 (aka kgateway Enterprise)
  if $GLOO_GATEWAY_V2_ENABLED; then
    GLOO_GATEWAY_V2_FLAG=enabled 
    GATEWAY_CLASS_NAME=gloo-gateway-v2
    INGRESS_ENABLED=true
    echo '#' Gloo Gateway V2 is enabled 
  fi

  # Spire
  $SPIRE_ENABLED && SPIRE_FLAG=enabled && echo '#' SPIRE is enabled

  # Cert-manager
  $CERT_MANAGER_ENABLED && CERT_MANAGER_FLAG=enabled && echo '#' Cert-manager is enabled

  # Keycloak and ExtAuth
  if $KEYCLOAK_ENABLED; then
    echo '#' Keycloak is enabled
    EXTAUTH_FLAG=enabled && echo '#' ExtAuth is enabled
    RATELIMITER_FLAG=enabled && echo '#' Rate-limiter is enabled
  fi

  set_defaults
}

function create_namespace {
  local _context _namespace
  _context=$1
  _namespace=$2

  $DRY_RUN kubectl "$GSI_MODE" namespace "$_namespace"                        \
  --context "$_context"
}
# END
