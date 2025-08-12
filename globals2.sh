#!/usr/bin/env bash
 ###############################################################################
# globals2.sh
# 
# functions for setting global state
###############################################################################
#-------------------------------------------------------------------------------
# Global versions of Helm Repos, Istio Repos, and Istio settings
#-------------------------------------------------------------------------------
export TEMPLATES CERTS UTAG MANIFESTS CERT_MANAGER_CERTS SPIRE_CERTS
TEMPLATES="$(dirname "$0")"/templates2
CERTS="$(dirname "$0")"/certs
SPIRE_CERTS="$(dirname "$0")"/spire-certs
CERT_MANAGER_CERTS="$(dirname "$0")"/cert-manager/certs

export REVISION GME_SECRET GME_SECRET_TOKEN TLDN MESH_ID
export ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR ISTIO_DISTRO ISTIO_126_FLAG
export GSI_MODE GSI_CLUSTER GSI_CONTEXT GSI_NETWORK
export GSI_REMOTE_CLUSTER GSI_REMOTE_CONTEXT GSI_REMOTE_NETWORK
export GSI_MGMT_CLUSTER GSI_MGMT_CONTEXT GSI_MGMT_NETWORK
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
export AZURE_ENABLED="${AZURE_ENABLED:-false}"
export GCP_ENABLED="${GCP_ENABLED:-false}"

# AWS
export AWS_ENABLED="${AWS_ENABLED:-false}"
export ROOT_CAARN ROOT_CERTARN SUBORDINATE_CAARN SUBORDINATE_CERTARN
export AWS_PCA_POLICY_ARN AWS_PCA_ROLE_ARN
export AWSPCA_ISSUER_VER=v1.6.0
export AWS_PROFILE=aws

# Namespaces
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
export HELLOWORLD_ENABLED=${HELLOWORLD_ENABLED:-false}
export HELLOWORLD_NAMESPACE=helloworld
export HELLOWORLD_SERVICE_NAME=helloworld
export HELLOWORLD_SERVICE_PORT=8001

export HTTPBIN_ENABLED=${HTTPBIN_ENABLED:-false}
export HTTPBIN_NAMESPACE=httpbin
export HTTPBIN_SERVICE_NAME=httpbin
export HTTPBIN_SERVICE_PORT=8002

export CURL_ENABLED=${CURL_ENABLED:-false}
export CURL_NAMESPACE=curl

# Tools 
export UTILS_ENABLED=${UTILS_ENABLED:-false}
export UTILS_NAMESPACE=tools

export NETSHOOT_ENABLED=${NETSHOOT_ENABLED:-false}
export NETSHOOT_NAMESPACE=tools

# External DNS
export EXTERNAL_DNS_ENABLED=${EXTERNAL_DNS_ENABLED:-false}

# ArgoCD
export ARGOCD_ENABLED=${ARGOCD_ENABLED:-false}
export ARGOCD_NAMESPACE=argocd

# Cert manager
export CERT_MANAGER_ENABLED="${CERT_MANAGER_ENABLED:-false}"
export CERT_MANAGER_VER="v1.18.2"
export CERT_MANAGER_NAMESPACE="cert-manager"
export CERT_MANAGER_INGRESS_SECRET="ingress-ca-key-pair"

# Spire
export SPIRE_ENABLED="${SPIRE_ENABLED:-false}"
export SPIRE_NAMESPACE=spire-server
export SPIRE_CRDS_VER=0.5.0
export SPIRE_SERVER_VER=0.26.0
export SPIRE_SECRET=spiffe-upstream-ca

# Istio Gateway
export ISTIO_GATEWAY_ENABLED=${ISTIO_GATEWAY_ENABLED:-false}
export TLS_TERMINATION_ENABLED=${TLS_TERMINATION_ENABLED:-false}
export TLS_TERMINATION_FLAG

# Gateway API
export EXPERIMENTAL_GATEWAY_API_CRDS=${EXPERIMENTAL_GATEWAY_API_CRDS:-false}
export GATEWAY_API_ENABLED=${GATEWAY_API_ENABLED:-false}

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
export GLOO_GATEWAY_V2_HELM_VER=2.0.0-alpha.3
export GLOO_GATEWAY_V2_NAMESPACE=gloo-gateway-system

export TRAFFIC_POLICY_NAME=oauth-authorization-code

# keycloak
export KEYCLOAK_ENABLED="${KEYCLOAK_ENABLED:-false}"
export KEYCLOAK_NAMESPACE=keycloak
export KEYCLOAK_VER=26.3
export KEYCLOAK_ENDPOINT KEYCLOAK_HOST KEYCLOAK_PORT KEYCLOAK_URL
export KEYCLOAK_TOKEN KEYCLOAK_CLIENT KEYCLOAK_SECRET
export EXTAUTH_ENABLED=${EXTAUTH_ENABLED:-false}
export RATELIMITER_ENABLED=${RATELIMITER_ENABLED:-false}

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
export ISTIO_VER_126=1.26.3
export ISTIO_SECRET=cacerts

# Dataplane Modes
export AMBIENT_ENABLED="${AMBIENT_ENABLED:-false}"
export SIDECAR_ENABLED="${SIDECAR_ENABLED:-false}"

# Gloo Edge (Gloo Gateway)
export GLOO_EDGE_ENABLED="${GLOO_EDGE_ENABLED:-false}"
export GLOO_EDGE_NAMESPACE=gloo-system

# GME
export GME_ENABLED="${GME_ENABLED:-false}"
export GME_NAMESPACE="gloo-mesh"
export GME_MGMT_AGENT_ENABLED="${GME_MGMT_AGENT_ENABLED:-false}"
export GME_VER_26="2.6.12"
export GME_VER_27="2.7.3"
export GME_VER_28="2.8.1"
export GME_VER_29="2.9.2"

export GME_GATEWAYS_WORKSPACE=gateways
export GME_APPLICATIONS_WORKSPACE=applications
export GME_VERBOSE=${GME_VERBOSE:-false}

export DEFAULT_GME="2.9"
export DEFAULT_GME_SECRET="relay-token"
export DEFAULT_GME_SECRET_TOKEN="my-lucky-secret-token"
export DEFAULT_MESH_ID="mesh"
export DEFAULT_TLDN=example.com
export DEFAULT_TRUST_DOMAIN="cluster.local"

export DEFAULT_GSI_MODE=create # create | delete

export GME_SECRET_TOKEN=${GME_SECRET_TOKEN:-$DEFAULT_GME_SECRET_TOKEN}
export GME_SECRET=${GME_SECRET:-$DEFAULT_GME_SECRET}
export TLDN=${TLDN:-$DEFAULT_TLDN}
export TRUST_DOMAIN=${TRUST_DOMAIN:-$DEFAULT_TRUST_DOMAIN}
export MESH_ID=${MESH_ID:-$DEFAULT_MESH_ID}

export GSI_MODE=${GSI_MODE:-$DEFAULT_GSI_MODE}

function set_gsi_mode {
  export GSI_MODE=${1:-$DEFAULT_GSI_MODE}
}

function enable_gme {
  export GME_ENABLED=true 
}

function disable_gme {
  export GME_ENABLED=false 
}

function set_revision {
  export REVISION="$1"
}

function set_istio {
  local _istio=$1
  local _flavor=$2
  local _variant=$3

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
  export GME_VER
  GME_VER=$(eval echo \$GME_VER_"${1//.}")
}

function gsi_set_defaults {
  set_revision main
  set_istio 1.26 solo distroless
  set_gme $DEFAULT_GME
}

function is_create_mode {
  if [[ $GSI_MODE =~ (create|apply) ]]; then
    return 0
  else
    return 1
  fi
}

function gsi_reset {
  UTAG=""
}

# For reproducibilty and sharing, we save the manifests
function set_utag {
  local _utag=${1:-$UTAG}
  export UTAG=${_utag:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8)}
  MANIFESTS="$(dirname "$0")"/manifests/$UTAG
}

function gsi_init {
##  # For reproducibilty and sharing, we save the manifests
##  UTAG=${UTAG:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8)}
##  MANIFESTS="$(dirname "$0")"/manifests/$UTAG
  set_utag
  mkdir -p "$MANIFESTS"
  echo "export MANIFESTS=$MANIFESTS"

  # Gloo Mesh Enterprise (GME)
  if $GME_ENABLED; then
    GME_FLAG=enabled  
    echo '#' GME is enabled
    if $GME_MGMT_AGENT_ENABLED; then
      GME_MGMT_AGENT_FLAG=enabled 
      echo '#' GME MGMT Agent is enabled
    fi
  fi

  # cloud / k8s providers
  $DOCKER_DESKTOP_ENABLED   && DOCKER_FLAG=enabled   && echo '#' Docker Desktop is enabled
  $AWS_ENABLED   && AWS_FLAG=enabled   && echo '#' AWS is enabled
  $AZURE_ENABLED && AZURE_FLAG=enabled && echo '#' AZURE is enabled
  $GCP_ENABLED && GCP_FLAG=enabled && echo '#' AZURE is enabled

  # Istio mesh mode
  $SIDECAR_ENABLED && SIDECAR_FLAG=enabled && echo '#' Istio Sidecar
  $AMBIENT_ENABLED && AMBIENT_FLAG=enabled && echo '#' Istio Ambient
  
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

  # TLS Termination for istio gateway EW
  $TLS_TERMINATION_ENABLED && TLS_TERMINATION_FLAG=enabled
  
  # Kgateway (OSS)
  if $KGATEWAY_ENABLED; then
    KGATEWAY_FLAG=enabled
    GATEWAY_CLASS_NAME=kgateway
    INGRESS_ENABLED=true
    GATEWAY_API_ENABLED=true
    echo '#' Kgateway is enabled  on "$GSI_CLUSTER"
  fi
  # Gloo Gateway V2 (aka kgateway Enterprise)
  if $GLOO_GATEWAY_V2_ENABLED; then
    GLOO_GATEWAY_V2_FLAG=enabled 
    GATEWAY_CLASS_NAME=gloo-gateway-v2
    INGRESS_ENABLED=true
    GATEWAY_API_ENABLED=true
    EXPERIMENTAL_GATEWAY_API_CRDS=true
    echo '#' Gloo Gateway V2 is enabled 
  fi

  # Spire
  $SPIRE_ENABLED && SPIRE_FLAG=enabled && echo '#' SPIRE is enabled

  # Cert-manager
  $CERT_MANAGER_ENABLED && CERT_MANAGER_FLAG=enabled && echo '#' Cert-manager is enabled

  # Keycloak and ExtAuth
  if $KEYCLOAK_ENABLED; then
    echo '#' Keycloak is enabled
    EXTAUTH_ENABLED=true && EXTAUTH_FLAG=enabled && echo '#' ExtAuth is enabled
    RATELIMITER_ENABLED=true && RATELIMITER_FLAG=enabled && echo '#' Rate-limiter is enabled
  fi

  gsi_set_defaults
}

function get_k8s_region {
  local _context
  _context=$1

  _region=$(kubectl get nodes                                                 \
    --context "$_context"                                                     \
    -o jsonpath='{.items[0].metadata.labels.topology\.kubernetes\.io/region}')

  echo "$_region"
}

function get_k8s_zones {
  local _context
  _context=$1

  _zones=$(kubectl get nodes                                                  \
           --context "$_context"                                              \
           -o yaml                                                            |
           yq '.items[].metadata.labels."topology.kubernetes.io/zone"'        |
           sort|uniq)

  echo "$_zones"
}

function gsi_cluster_swap {
  export NEW_GSI_REMOTE_CLUSTER=$GSI_CLUSTER
  export NEW_GSI_REMOTE_CONTEXT=$GSI_CONTEXT
  export NEW_GSI_REMOTE_NETWORK=$GSI_NETWORK
  export NEW_REMOTE_AWS_REGION=$AWS_REGION
  export NEW_REMOTE_TRUST_DOMAIN=$TRUST_DOMAIN
  
  export NEW_GSI_LOCAL_CLUSTER=$GSI_REMOTE_CLUSTER
  export NEW_GSI_LOCAL_CONTEXT=$GSI_REMOTE_CONTEXT
  export NEW_GSI_LOCAL_NETWORK=$GSI_REMOTE_NETWORK
  export NEW_LOCAL_AWS_REGION=$REMOTE_AWS_REGION
  export NEW_LOCAL_TRUST_DOMAIN=${REMOTE_TRUST_DOMAIN:-$TRUST_DOMAIN}

  export GSI_CLUSTER=$NEW_GSI_LOCAL_CLUSTER
  export GSI_CONTEXT=$NEW_GSI_LOCAL_CONTEXT
  export GSI_NETWORK=$NEW_GSI_LOCAL_NETWORK
  export AWS_REGION=$NEW_LOCAL_AWS_REGION
  export TRUST_DOMAIN=$NEW_LOCAL_TRUST_DOMAIN

  export GSI_REMOTE_CLUSTER=$NEW_GSI_REMOTE_CLUSTER
  export GSI_REMOTE_CONTEXT=$NEW_GSI_REMOTE_CONTEXT
  export GSI_REMOTE_NETWORK=$NEW_GSI_REMOTE_NETWORK
  export REMOTE_AWS_REGION=$NEW_REMOTE_AWS_REGION
  export REMOTE_TRUST_DOMAIN=$NEW_REMOTE_TRUST_DOMAIN
}

function _f_debug {
  local _cmd=$1
  if [[ $DRY_RUN == echo ]]; then
    cat "$_cmd"
  else
    # shellcheck disable=SC1090
    source "$_cmd"
  fi
}

function wait_for_pods {
  local _namespace=$1
  local _app=$2


}

# END
