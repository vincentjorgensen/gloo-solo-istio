#!/usr/bin/env bash
 ###############################################################################
# globals.sh
# 
# Env vars and functions for setting global state of the k8s clusters
###############################################################################
export J2_GLOBALS UTAG
#-------------------------------------------------------------------------------
# Directories
#-------------------------------------------------------------------------------
export TEMPLATES CERTS MANIFESTS CERT_MANAGER_CERTS SPIRE_CERTS REPLAYS
TEMPLATES="$(dirname "$0")"/templates
CERTS="$(dirname "$0")"/certs
SPIRE_CERTS="$(dirname "$0")"/spire-certs
CERT_MANAGER_CERTS="$(dirname "$0")"/cert-manager/certs
REPLAYS="$(dirname "$0")"/replays
INFRAS="$(dirname "$0")"/infras

#-------------------------------------------------------------------------------
# Namespaces
#-------------------------------------------------------------------------------
export KUBE_SYSTEM_NAMESPACE=kube-system

###############################################################################
# K8s Providers
###############################################################################
#-------------------------------------------------------------------------------
# Docker Desktop Settings
#-------------------------------------------------------------------------------
export DOCKER_DESKTOP_ENABLED=${DOCKER_DESKTOP_ENABLED:-true}
export DOCKER_DESKTOP_FLAG

#-------------------------------------------------------------------------------
# Google GCP Seettings
#-------------------------------------------------------------------------------
export GCP_ENABLED="${GCP_ENABLED:-false}"
export GCP_FLAG

#-------------------------------------------------------------------------------
# Amazon AWS Settings
#-------------------------------------------------------------------------------
export AWS_ENABLED=${AWS_ENABLED:-false}
export ROOT_CAARN ROOT_CERTARN SUBORDINATE_CAARN SUBORDINATE_CERTARN
export AWS_PCA_POLICY_ARN AWS_PCA_ROLE_ARN
export AWSPCA_ISSUER_VER=v1.6.0
export AWS_PROFILE=aws
export COGNITO_JWT_ROUTE_OPTION=jwt-cognito
export COGNITO_ISSUER="https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ZrUc2TqWw"
export COGNITO_KEEP_TOKEN='true'
export AWS_FLAG COGNITO_ISSUER_FQDN

#-------------------------------------------------------------------------------
# Microsoft Azure Settings
#-------------------------------------------------------------------------------
export AZURE_ENABLED=${AZURE_ENABLED:-false}
export AZURE_FLAG

###############################################################################
# Testing Apps
###############################################################################
#-------------------------------------------------------------------------------
# Homegrown Helloworld App
#-------------------------------------------------------------------------------
export HELLOWORLD_ENABLED=${HELLOWORLD_ENABLED:-false}
export HELLOWORLD_NAMESPACE=helloworld
export HELLOWORLD_SERVICE_NAME=helloworld
export HELLOWORLD_SERVICE_PORT=8001
export HELLOWORLD_CONTAINER_PORT=8080
export HELLOWORLD_SIZE=1
export REMOTE_HELLOWORLD_ENABLED=${REMOTE_HELLOWORLD_ENABLED:-false}

#-------------------------------------------------------------------------------
# HTTPBIN App
#-------------------------------------------------------------------------------
export HTTPBIN_ENABLED=${HTTPBIN_ENABLED:-false}
export HTTPBIN_NAMESPACE=httpbin
export HTTPBIN_SERVICE_NAME=httpbin
export HTTPBIN_SERVICE_PORT=8002
export HTTPBIN_CONTAINER_PORT=8080
export HTTPBIN_SIZE=1

#-------------------------------------------------------------------------------
# Curl App
#-------------------------------------------------------------------------------
export CURL_ENABLED=${CURL_ENABLED:-false}
export CURL_NAMESPACE=tools

#-------------------------------------------------------------------------------
# Utils App 
#-------------------------------------------------------------------------------
export UTILS_ENABLED=${UTILS_ENABLED:-false}
export UTILS_NAMESPACE=tools

#-------------------------------------------------------------------------------
# NetShoot App
#-------------------------------------------------------------------------------
export NETSHOOT_ENABLED=${NETSHOOT_ENABLED:-false}
export NETSHOOT_NAMESPACE=tools

###############################################################################
# Integration Tools
###############################################################################
#-------------------------------------------------------------------------------
# External DNS
#-------------------------------------------------------------------------------
export EXTERNAL_DNS_ENABLED=${EXTERNAL_DNS_ENABLED:-false}
export EXTERNAL_DNS_VER=1.18.0

#-------------------------------------------------------------------------------
# ArgoCD
#-------------------------------------------------------------------------------
export ARGOCD_ENABLED=${ARGOCD_ENABLED:-false}
export ARGOCD_VER="8.5.7" # "8.2.5"
export ARGOCD_NAMESPACE=argocd

#-------------------------------------------------------------------------------
# Cert manager
#-------------------------------------------------------------------------------
export CERT_MANAGER_ENABLED=${CERT_MANAGER_ENABLED:-false}
export CERT_MANAGER_VER="v1.18.2"
export CERT_MANAGER_NAMESPACE="cert-manager"
export CERT_MANAGER_INGRESS_SECRET="ingress-ca-key-pair"
export CLUSTER_ISSUER="selfsigned-cluster-issuer"
export CERT_MANAGER_FLAG

#-------------------------------------------------------------------------------
# Spire
#-------------------------------------------------------------------------------
export SPIRE_ENABLED="${SPIRE_ENABLED:-false}"
export SPIRE_NAMESPACE=spire-server
export SPIRE_CRDS_VER=0.5.0
export SPIRE_SERVER_VER=0.26.0
export SPIRE_SECRET=spiffe-upstream-ca
export SPIRE_FLAG

###############################################################################
# Ingress, Egress, and Eastwest Gateways
###############################################################################
#-------------------------------------------------------------------------------
# Ingress Gateway Settings
#-------------------------------------------------------------------------------
export INGRESS_ENABLED=${INGRESS_ENABLED:-false}
export INGRESS_NAMESPACE=ingress-gateways
export INGRESS_GATEWAY=ingress-gateway
export INGRESS_HTTP_PORT=80
export INGRESS_HTTPS_PORT=443
export INGRESS_SIZE=1
export DEFAULT_TLDN=example.com
export TLDN=${TLDN:-$DEFAULT_TLDN}
export PROMETHEUS_ENABLED=${PROMETHEUS_ENABLED:-false}
export HTTP_FLAG HTTPS_FLAG INGRESS_GATEWAY_CLASS PROMETHEUS_FLAG

#-------------------------------------------------------------------------------
# Gloo Mesh Gateway (GMG)
#-------------------------------------------------------------------------------
export GLOO_MESH_GATEWAY_ENABLED=${GLOO_MESH_GATEWAY_ENABLED:-false}
export GLOO_MESH_GATEWAY_VER=2.10.0
export GLOO_MESH_GATEWAY_FLAG

#-------------------------------------------------------------------------------
# Gateway API
#-------------------------------------------------------------------------------
export EXPERIMENTAL_GATEWAY_API_CRDS=${EXPERIMENTAL_GATEWAY_API_CRDS:-false}
export GATEWAY_API_ENABLED=${GATEWAY_API_ENABLED:-false}

#-------------------------------------------------------------------------------
# Eastwest Gateway Settings
#-------------------------------------------------------------------------------
export MULTICLUSTER_ENABLED=${MULTICLUSTER_ENABLED:-false}
export EASTWEST_NAMESPACE=eastwest-gateways
export EASTWEST_GATEWAY=eastwest-gateway
export MULTICLUSTER_NAMESPACE=$EASTWEST_NAMESPACE
export EASTWEST_SIZE=1
export EASTWEST_GATEWAY_CLASS MC_FLAG EASTWEST_REMOTE_GATEWAY_CLASS

#-------------------------------------------------------------------------------
# Ingress as Istio Gateway (OSS)
#-------------------------------------------------------------------------------
export ISTIO_GATEWAY_ENABLED=${ISTIO_GATEWAY_ENABLED:-false}
export TLS_TERMINATION_ENABLED=${TLS_TERMINATION_ENABLED:-false}
export TLS_TERMINATION_FLAG ISTIO_GATEWAY_FLAG

#-------------------------------------------------------------------------------
# Ingress as Gloo Edge
#-------------------------------------------------------------------------------
export GLOO_EDGE_ENABLED=${GLOO_EDGE_ENABLED:-false}
export GLOO_EDGE_NAMESPACE=gloo-system
export GLOO_EDGE_VER=1.19.10
export GLOO_EDGE_FLAG

#-------------------------------------------------------------------------------
# Ingress as KGateway (OSS)
#-------------------------------------------------------------------------------
export KGATEWAY_ENABLED=${KGATEWAY_ENABLED:-false}
export KGATEWAY_NAMESPACE=kgateway-system
export KGATEWAY_VER=v1.2.1
export KGATEWAY_EXPERIMENTAL_VER=v1.3.0
export KGATEWAY_CRDS_HELM_REPO=oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds
export KGATEWAY_HELM_REPO=oci://cr.kgateway.dev/kgateway-dev/charts/kgateway
export KGATEWAY_HELM_VER=v2.0.3
export KGATEWAY_FLAG

#-------------------------------------------------------------------------------
# Ingress as Gloo Gateway, v1 or v2
#-------------------------------------------------------------------------------
export EXTAUTH_ENABLED=${EXTAUTH_ENABLED:-false}
export RATELIMITER_ENABLED=${RATELIMITER_ENABLED:-false}
export RATELIMITER_FLAG EXTAUTH_FLAG GLOO_GATEWAY_NAMESPACE

#-------------------------------------------------------------------------------
# Ingress as Gloo Gateway V1 (Gateway API with Edge underneath)
#-------------------------------------------------------------------------------
export GLOO_GATEWAY_V1_ENABLED=${GLOO_GATEWAY_V1_ENABLED:-false}
export GLOO_GATEWAY_V1_NAMESPACE=gloo-system
export GLOO_GATEWAY_V1_VER=1.20.1
export GLOO_GATEWAY_V1_FLAG

#-------------------------------------------------------------------------------
# Ingress as Gloo Gateway V2 (Gateway API)
#-------------------------------------------------------------------------------
export GLOO_GATEWAY_V2_ENABLED=${GLOO_GATEWAY_V2_ENABLED:-false}
export GLOO_GATEWAY_V2_NAMESPACE=gloo-system
export GLOO_GATEWAY_V2_CRDS_HELM_REPO=oci://us-docker.pkg.dev/solo-public/gloo-gateway/charts/gloo-gateway-crds
export GLOO_GATEWAY_V2_HELM_REPO=oci://us-docker.pkg.dev/solo-public/gloo-gateway/charts/gloo-gateway
export GLOO_GATEWAY_V2_VER=2.0.0-rc.2
export TRAFFIC_POLICY=oauth-authorization-code
export GLOO_GATEWAY_V2_FLAG

#-------------------------------------------------------------------------------
# Keycloak
#-------------------------------------------------------------------------------
export KEYCLOAK_ENABLED=${KEYCLOAK_ENABLED:-false}
export KEYCLOAK_NAMESPACE=keycloak
export KEYCLOAK_VER=26.3
export KEYCLOAK_ENDPOINT KEYCLOAK_HOST KEYCLOAK_PORT KEYCLOAK_URL KEYCLOAK_FLAG
export KEYCLOAK_TOKEN KEYCLOAK_CLIENT KEYCLOAK_SECRET KEYCLOAK_ID

###############################################################################
# All things Istio
###############################################################################
#-------------------------------------------------------------------------------
# Istio Versions
#-------------------------------------------------------------------------------
export ISTIO_ENABLED=${ISTIO_ENABLED:-false}
export ISTIO_NAMESPACE=istio-system
export AMBIENT_NAMESPACE=$ISTIO_NAMESPACE
export SIDECAR_NAMESPACE=$ISTIO_NAMESPACE
export PEERING_DISCOVERY_SUFFIX="mesh.internal"
export HELM_REPO_123=oci://us-docker.pkg.dev/gloo-mesh/istio-helm-207627c16668
export ISTIO_REPO_123=us-docker.pkg.dev/gloo-mesh/istio-207627c16668
export ISTIO_VER_123=1.23.6-patch2
export HELM_REPO_124=oci://us-docker.pkg.dev/gloo-mesh/istio-helm-4d37697f9711
export ISTIO_REPO_124=us-docker.pkg.dev/gloo-mesh/istio-4d37697f9711
export ISTIO_VER_124=1.24.6-patch0
export HELM_REPO_125=oci://us-docker.pkg.dev/soloio-img/istio-helm
export ISTIO_REPO_125=us-docker.pkg.dev/soloio-img/istio
export ISTIO_VER_125=1.25.3-patch0
export HELM_REPO_126=oci://us-docker.pkg.dev/soloio-img/istio-helm
export ISTIO_REPO_126=us-docker.pkg.dev/soloio-img/istio
export ISTIO_VER_126=1.26.4
export HELM_REPO_127=oci://us-docker.pkg.dev/soloio-img/istio-helm
export ISTIO_REPO_127=us-docker.pkg.dev/soloio-img/istio
export ISTIO_VER_127=1.27.1-patch1
export ISTIO_SECRET=cacerts
export DEFAULT_MESH_ID="mesh"
export DEFAULT_TRUST_DOMAIN="cluster.local"
export TRUST_DOMAIN=${TRUST_DOMAIN:-$DEFAULT_TRUST_DOMAIN}
export MESH_ID=${MESH_ID:-$DEFAULT_MESH_ID}
export ISTIO_PEER_AUTH_MODE="STRICT" # STRICT, PERMISSIVE, UNSET, DISABLED (not allowed for ztunnel)
export SIDECAR_INJECTOR_WEBHOOKS_ENABLED=${SIDECAR_INJECTOR_WEBHOOKS_ENABLED:-false}
# Traffic Distribution: PreferNetwork, PreferClose, PreferRegion, Any
export ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR ISTIO_DISTRO ISTIO_126_FLAG
export REVISION TRAFFIC_DISTRIBUTION SIDECAR_INJECTOR_WEBHOOKS_FLAG

#-------------------------------------------------------------------------------
# Istio Dataplane Modes
#-------------------------------------------------------------------------------
export AMBIENT_ENABLED=${AMBIENT_ENABLED:-false}
export SIDECAR_ENABLED=${SIDECAR_ENABLED:-false}
export SIDECAR_FLAG AMBIENT_FLAG

#-------------------------------------------------------------------------------
# Gloo Mesh Enterprise (GME)
#-------------------------------------------------------------------------------
export GME_ENABLED=${GME_ENABLED:-false}
export GME_NAMESPACE="gloo-mesh"
export GME_MGMT_AGENT_ENABLED=${GME_MGMT_AGENT_ENABLED:-false}
export GME_VER_26="2.6.13"
export GME_VER_27="2.7.6"
export GME_VER_28="2.8.3"
export GME_VER_29="2.9.2"
export GME_VER_210="2.10.1"
export GME_GATEWAYS_WORKSPACE=gateways
export GME_APPLICATIONS_WORKSPACE=applications
export GME_VERBOSE=${GME_VERBOSE:-false}
export DEFAULT_GME_VER="2.10"
export DEFAULT_GME_SECRET="relay-token"
export DEFAULT_GME_SECRET_TOKEN="my-lucky-secret-token"
export GME_SECRET=${GME_SECRET:-$DEFAULT_GME_SECRET}
export GME_SECRET_TOKEN=${GME_SECRET_TOKEN:-$DEFAULT_GME_SECRET_TOKEN}
export GME_ANALYZER_ENABLED=true
export GME_INSIGHTS_ENABLED=true
export GME_GLOOUI_SERVICE_TYPE=${GME_GLOOUI_SERVICE_TYPE:-LoadBalancer}
export GME_MGMT_SERVICE_TYPE=${GME_GLOOUI_SERVICE_TYPE:-ClusterIP}
export GME_TELEMETRY_SERVICE_TYPE=${GME_TELEMETRY_SERVICE_TYPE:-ClusterIP}
export GME_FLAG GME_MGMT_AGENT_FLAG

###############################################################################
# Gloo Solo Istio (GSI)
###############################################################################
#-------------------------------------------------------------------------------
# Current cluster identifiers
#-------------------------------------------------------------------------------
export GSI_MODE GSI_CLUSTER GSI_CONTEXT GSI_NETWORK
export GSI_REMOTE_CLUSTER GSI_REMOTE_CONTEXT GSI_REMOTE_NETWORK
export GSI_MGMT_CLUSTER GSI_MGMT_CONTEXT GSI_MGMT_NETWORK

#-------------------------------------------------------------------------------
# GSI runtime flags
#-------------------------------------------------------------------------------
export DEFAULT_GSI_MODE=apply # create | apply | delete
export GSI_MODE=${GSI_MODE:-$DEFAULT_GSI_MODE}
export DRY_RUN=${DRY_RUN:-} # Testing and generating reproducible plans

function set_gsi_mode {
  export GSI_MODE=${1:-$DEFAULT_GSI_MODE}
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
##  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 27 ]]; then
##    ISTIO_126_FLAG="enabled"
##  fi
}

function set_gme {
  local _gme_ver=${1:-$GME_VER}
  if [[ -z $_gme_ver ]]; then
    GME_VER=$(eval echo \$GME_VER_"${DEFAULT_GME_VER//.}")
  fi
}

function gsi_set_defaults {
  set_revision main
  set_istio 1.26 solo distroless
  set_gme
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
  UTAG=${_utag:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8)}
  MANIFESTS="$(dirname "$0")"/manifests/$UTAG
}

function gsi_init {
  set_utag "$1"
  mkdir -p "$MANIFESTS"
  echo "export MANIFESTS=$MANIFESTS"

  eval unset GATEWAY_API_CRDS_APPLIED_"${GSI_CLUSTER//-/_}"
  eval unset GATEWAY_API_CRDS_APPLIED_"${GSI_REMOTE_CLUSTER//-/_}"

  if [[ -e $INFRAS/infra_${UTAG}.sh ]]; then
    # shellcheck disable=SC1090
    source "$INFRAS/infra_${UTAG}.sh"
  fi

  #############################################################################
  # Support infrastructure which affects later fields
  #############################################################################
  #----------------------------------------------------------------------------
  # Gloo Mesh Enterprise (GME)
  #----------------------------------------------------------------------------
  if $GME_ENABLED; then
    GME_FLAG=enabled  
    echo '#' GME is enabled
    if [[ $GSI_MGMT_CLUSTER == "$GSI_CLUSTER" ]]; then
      GME_MGMT_AGENT_ENABLED=true
    fi
    if $GME_MGMT_AGENT_ENABLED; then
      GME_MGMT_AGENT_FLAG=enabled 
      echo '#' GME MGMT Agent is enabled
    fi
    if $MULTICLUSTER_ENABLED; then
      GME_MGMT_SERVICE_TYPE=LoadBalancer
      GME_TELEMETRY_SERVICE_TYPE=LoadBalancer
      echo '#' GME MGMT Multicluster is enabled
    fi
  fi
  #----------------------------------------------------------------------------
  # Spire
  #----------------------------------------------------------------------------
  if $SPIRE_ENABLED; then
    SPIRE_FLAG=enabled
    echo '#' SPIRE is enabled
  fi

  #----------------------------------------------------------------------------
  # Cert-manager
  #----------------------------------------------------------------------------
  if $CERT_MANAGER_ENABLED; then
    CERT_MANAGER_FLAG=enabled 
    HTTPS_FLAG=enabled
    echo '#' Cert-manager is enabled
  fi

  #----------------------------------------------------------------------------
  # Keycloak and ExtAuth
  #----------------------------------------------------------------------------
  if $KEYCLOAK_ENABLED; then
    KEYCLOAK_FLAG=enabled
    EXTAUTH_ENABLED=true
    RATELIMITER_ENABLED=true
    echo '#' Keycloak is enabled
  fi

  #############################################################################
  # k8s providers
  #############################################################################
  if $DOCKER_DESKTOP_ENABLED; then
    DOCKER_DESKTOP_FLAG=enabled
    echo '#' Docker Desktop is enabled
  fi
  if $AWS_ENABLED; then
    AWS_FLAG=enabled
    # shellcheck disable=SC2299
    COGNITO_ISSUER_FQDN="${${COGNITO_ISSUER_URL##*//}%%/*}"
    echo '#' Amazon AWS is enabled
  fi
  if $AZURE_ENABLED; then
    AZURE_FLAG=enabled
    echo '#' Microsoft AZURE is enabled
  fi
  if $GCP_ENABLED; then
    GCP_FLAG=enabled
    echo '#' Google GCP is enabled
  fi

  #----------------------------------------------------------------------------
  # Istio mesh mode
  #----------------------------------------------------------------------------
  if $SIDECAR_INJECTOR_WEBHOOKS_ENABLED; then
    SIDECAR_INJECTOR_WEBHOOKS_FLAG=enabled
  fi
  if $SIDECAR_ENABLED; then
    ISTIO_ENABLED=true
    SIDECAR_FLAG=enabled
    echo '#' Istio Sidecar dataplane is enabled
  fi
  if $AMBIENT_ENABLED; then
    ISTIO_ENABLED=true
    AMBIENT_FLAG=enabled
    echo '#' Istio Ambient dataplane is enabled
  fi
  
  #----------------------------------------------------------------------------
  # Multicluster
  #----------------------------------------------------------------------------
  if $MULTICLUSTER_ENABLED; then
    MC_FLAG=enabled
    echo '#' Multicluster is enabled 
    if $AMBIENT_ENABLED; then
      EASTWEST_GATEWAY_CLASS=istio-eastwest
      EASTWEST_REMOTE_GATEWAY_CLASS=istio-remote
      echo '#' Ambient Multicluster is enabled
    fi
  fi

  # TLS Termination for istio gateway EW
  if $TLS_TERMINATION_ENABLED; then
    TLS_TERMINATION_FLAG=enabled
    echo '#' TLS Termination is enabled
  fi 

  #############################################################################
  # Gateways
  #############################################################################
  #----------------------------------------------------------------------------
  # Gloo Mesh Gateway (GMG)
  #----------------------------------------------------------------------------
  if $GLOO_MESH_GATEWAY_ENABLED; then
    INGRESS_ENABLED=true
    GLOO_MESH_GATEWAY_FLAG=enabled
    echo '# '"Gloo Mesh Gateway (GMG) is enabled"
  fi
  #----------------------------------------------------------------------------
  # Kgateway (OSS)
  #----------------------------------------------------------------------------
  if $KGATEWAY_ENABLED; then
    GATEWAY_API_ENABLED=true
    KGATEWAY_FLAG=enabled
    INGRESS_GATEWAY_CLASS=kgateway
    INGRESS_ENABLED=true
    echo '#' Kgateway is enabled
  fi
  #----------------------------------------------------------------------------
  # Gloo Gateway V1 (Gateway API)
  #----------------------------------------------------------------------------
  if $GLOO_GATEWAY_V1_ENABLED; then
    GATEWAY_API_ENABLED=true # Use GLOO_EDGE_ENABLED for Edge API
    GLOO_GATEWAY_V1_FLAG=enabled 
    GLOO_GATEWAY_NAMESPACE=$GLOO_GATEWAY_V1_NAMESPACE 
    INGRESS_GATEWAY_CLASS=gloo-gateway
    INGRESS_ENABLED=true
    echo '#' Gateway API CRDs are enabled
    echo '#' Gloo Gateway V1 is enabled "(Gateway API)"
  fi
  #----------------------------------------------------------------------------
  # Gloo Gateway V2 (Gateway API)
  #----------------------------------------------------------------------------
  if $GLOO_GATEWAY_V2_ENABLED; then
    GATEWAY_API_ENABLED=true # Implicit in V2
    GLOO_GATEWAY_V2_FLAG=enabled 
    GLOO_GATEWAY_NAMESPACE=$GLOO_GATEWAY_V2_NAMESPACE 
    INGRESS_GATEWAY_CLASS=gloo-gateway-v2
    INGRESS_ENABLED=true
    EXPERIMENTAL_GATEWAY_API_CRDS=true
    echo '#' Experimental Gateway API CRDs are enabled
    echo '#' Gloo Gateway V2 is enabled "(Gateway API)"
  fi
  #----------------------------------------------------------------------------
  # Gloo Edge API (Gloo Gateway V1)
  #----------------------------------------------------------------------------
  if $GLOO_EDGE_ENABLED; then
    GLOO_EDGE_FLAG=enabled
    INGRESS_ENABLED=true
    echo '#' Gloo Edge is enabled "(Gloo Gateway V1 with Edge API)"
  fi
  #----------------------------------------------------------------------------
  # Gateway ExtAuth
  #----------------------------------------------------------------------------
  if $EXTAUTH_ENABLED; then
    EXTAUTH_FLAG=enabled
    echo '#' ExtAuth is enabled
  fi
  #----------------------------------------------------------------------------
  # Gateway Rate-Limit
  #----------------------------------------------------------------------------
  if $RATELIMITER_ENABLED; then
    RATELIMITER_FLAG=enabled
    echo '#' Rate-limiter is enabled
  fi
  #----------------------------------------------------------------------------
  # Solo Prometheus
  #----------------------------------------------------------------------------
  if $PROMETHEUS_ENABLED; then
    PROMETHEUS_FLAG=enabled
    echo '#' Solo Prometheus is enabled
  fi

  #############################################################################
  # Apps and Utilities
  #############################################################################
  if $HELLOWORLD_ENABLED; then
    echo '#' Helloworld is enabled
  fi
  if $HTTPBIN_ENABLED; then
    echo '#' HTTPBIN is enabled
  fi
  if $CURL_ENABLED; then
    echo '#' Curl is enabled
  fi
  if $UTILS_ENABLED; then
    echo '#' Utils is enabled
  fi
  if $NETSHOOT_ENABLED; then
    echo '#' NetShoot is enabled
  fi

  #############################################################################
  # Set defaults based on pre-config
  # Generate the Global J2 parameters
  #############################################################################
  gsi_set_defaults
  _jinja2_values
}

function _get_k8s_region {
  local _context _region
  _context=$1

  _region=$(kubectl get nodes                                                  \
    --context "$_context"                                                      \
    -o jsonpath='{.items[0].metadata.labels.topology\.kubernetes\.io/region}')

  echo "$_region"
}

function _get_k8s_zones {
  local _context _zones
  _context=$1

  _zones=$(kubectl get nodes                                                   \
           --context "$_context"                                               \
           -o yaml                                                            |\
           yq '.items[].metadata.labels."topology.kubernetes.io/zone"'        |\
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

function _wait_for_pods {
  local _context=$1
  local _namespace=$2
  local _app=$3

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                      \
    --context "$_context"                                                      \
    --namespace "$_namespace"                                                  \
    --for=condition=Ready pods -l app="$_app"     
  fi
}

function _label_namespace {
  local _namespace=$1
  local _key=$2
  local _value=$3
  local _k_label="=${_value}"

    if ! is_create_mode; then
      _k_label="-"
    fi

  $DRY_RUN kubectl label namespace                                             \
  "$_namespace"                                                                \
  "${_key}${_k_label}"                                                         \
  --context "$GSI_CONTEXT" --overwrite
}

function _label_ns_for_istio {
  local _namespace=$1
  local _k_label _k_key

  if $AMBIENT_ENABLED; then
    local _k_label="=ambient"

    if ! is_create_mode; then
      _k_label="-"
    fi
    $DRY_RUN kubectl label namespace                                           \
    "$_namespace"                                                              \
    "istio.io/dataplane-mode${_k_label}"                                       \
    --context "$GSI_CONTEXT" --overwrite
  fi

  if $SIDECAR_ENABLED; then
    if [[ -n "$REVISION" ]]; then
      local _k_key="istio.io/rev"
      local _k_label="=${REVISION}"
    else
      local _k_key="istio-injection"
      local _k_label="=enabled"
    fi

    if ! is_create_mode; then
      _k_label="-"
    fi
    $DRY_RUN kubectl label namespace "$_namespace" "${_k_key}${_k_label}"      \
    --context "$GSI_CONTEXT" --overwrite
  fi
}

function _make_manifest {
  local _template=$1

  jinja2                                                                       \
       -D cluster="$GSI_CLUSTER"                                               \
       -D network="$GSI_NETWORK"                                               \
       -D trust_domain="$TRUST_DOMAIN"                                         \
       -D remote_cluster="$REMOTE_CLUSTER"                                     \
       -D remote_trust_domain="$REMOTE_TRUST_DOMAIN"                           \
       "$_template"                                                            \
       "$J2_GLOBALS"
}

function _apply_manifest {
  local _manifest=$1

  $DRY_RUN kubectl "$GSI_MODE"                                                 \
  --context "$GSI_CONTEXT"                                                     \
  -f "$_manifest"
}

function _jinja2_values {
  local _region _zones
  J2_GLOBALS="$MANIFESTS"/jinja2_globals.yaml

  _region=$(_get_k8s_region "$GSI_CONTEXT")
  _zones=$(_get_k8s_zones "$GSI_CONTEXT")

  echo "zones:" > "$J2_GLOBALS"

  while read -r zone; do
    echo "- $zone" >> "$J2_GLOBALS"
  done <<< "$_zones"

  jinja2                                                                       \
         -D ambient_enabled="$AMBIENT_FLAG"                                    \
         -D aws_enabled="$AWS_FLAG"                                            \
         -D azure_enabled="$AZURE_FLAG"                                        \
         -D cert_manager_enabled="$CERT_MANAGER_FLAG"                          \
         -D cert_manager_ingress_secret="$CERT_MANAGER_INGRESS_SECRET"         \
         -D cert_manager_namespace="$CERT_MANAGER_NAMESPACE"                   \
         -D cluster_issuer="$CLUSTER_ISSUER"                                   \
         -D cognito_issuer_fqdn="$COGNITO_ISSUER_FQDN"                         \
         -D cognito_issuer_url="$COGNITO_ISSUER"                               \
         -D cognito_jwt_route_option_name="$COGNITO_JWT_ROUTE_OPTION"          \
         -D cognito_keep_token_bool="$COGNITO_KEEP_TOKEN"                      \
         -D curl_namespace="$CURL_NAMESPACE"                                   \
         -D docker_desktop_enabled="$DOCKER_DESKTOP_ENABLED"                   \
         -D eastwest_gateway_class="$EASTWEST_GATEWAY_CLASS"                   \
         -D eastwest_remote_gateway_class="$EASTWEST_REMOTE_GATEWAY_CLASS"     \
         -D eastwest_gateway="$EASTWEST_GATEWAY"                               \
         -D eastwest_namespace="$EASTWEST_NAMESPACE"                           \
         -D eastwest_size="$EASTWEST_SIZE"                                     \
         -D extauth_enabled="$EXTAUTH_FLAG"                                    \
         -D gcp_enabled="$GCP_FLAG"                                            \
         -D gloo_edge_enabled="$GLOO_EDGE_FLAG"                                \
         -D gloo_edge_namespace="$GLOO_EDGE_NAMESPACE"                         \
         -D gloo_gateway_license_key="$GLOO_GATEWAY_LICENSE_KEY"               \
         -D gloo_gateway_namespace="$GLOO_GATEWAY_NAMESPACE"                   \
         -D gloo_gateway_v1_enabled="$GLOO_GATEWAY_V1_FLAG"                    \
         -D gloo_gateway_v2_enabled="$GLOO_GATEWAY_V2_FLAG"                    \
         -D gloo_mesh_gateway_enabled="$GLOO_MESH_GATEWAY_FLAG"                \
         -D gloo_mesh_license_key="$GLOO_MESH_LICENSE_KEY"                     \
         -D gme_analyzer_enabled="$GME_ANALYZER_ENABLED"                       \
         -D gme_glooui_service_type="$GME_GLOOUI_SERVICE_TYPE"                 \
         -D gme_insights_enabled="$GME_ANALYZER_ENABLED"                       \
         -D gme_mgmt_agent_enabled="$GME_MGMT_AGENT_FLAG"                      \
         -D gme_mgmt_cluster="$GSI_MGMT_CLUSTER"                               \
         -D gme_mgmt_service_type="$GME_MGMT_SERVICE_TYPE"                     \
         -D gme_namespace="$GME_NAMESPACE"                                     \
         -D gme_secret_token="$GME_SECRET_TOKEN"                               \
         -D gme_secret="$GME_SECRET"                                           \
         -D gme_telemetry_service_type="$GME_TELEMETRY_SERVICE_TYPE"           \
         -D gme_verbose="$GME_VERBOSE"                                         \
         -D helloworld_container_port="$HELLOWORLD_CONTAINER_PORT"             \
         -D helloworld_namespace="$HELLOWORLD_NAMESPACE"                       \
         -D helloworld_service_name="$HELLOWORLD_SERVICE_NAME"                 \
         -D helloworld_service_port="$HELLOWORLD_SERVICE_PORT"                 \
         -D helloworld_size="$HELLOWORLD_SIZE"                                 \
         -D httpbin_container_port="$HTTPBIN_CONTAINER_PORT"                   \
         -D httpbin_namespace="$HTTPBIN_NAMESPACE"                             \
         -D httpbin_service_name="$HTTPBIN_SERVICE_NAME"                       \
         -D httpbin_service_port="$HTTPBIN_SERVICE_PORT"                       \
         -D httpbin_size="$HTTPBIN_SIZE"                                       \
         -D https_enabled="$HTTPS_FLAG"                                        \
         -D ingress_gateway_class="$INGRESS_GATEWAY_CLASS"                     \
         -D ingress_gateway="$INGRESS_GATEWAY"                                 \
         -D ingress_http_port="$INGRESS_HTTP_PORT"                             \
         -D ingress_https_port="$INGRESS_HTTPS_PORT"                           \
         -D ingress_namespace="$INGRESS_NAMESPACE"                             \
         -D ingress_size="$INGRESS_SIZE"                                       \
         -D istio_126_enabled="$ISTIO_126_FLAG"                                \
         -D istio_enabled="$ISTIO_ENABLED"                                     \
         -D istio_flavor="$ISTIO_FLAVOR"                                       \
         -D istio_namespace="$ISTIO_NAMESPACE"                                 \
         -D istio_peer_auth_mode="$ISTIO_PEER_AUTH_MODE"                       \
         -D istio_repo="$ISTIO_REPO"                                           \
         -D istio_revision="$REVISION"                                         \
         -D istio_secret="$ISTIO_SECRET"                                       \
         -D istio_traffic_distribution="${TRAFFIC_DISTRIBUTION:-Any}"          \
         -D istio_variant="$ISTIO_DISTRO"                                      \
         -D istio_ver="$ISTIO_VER"                                             \
         -D keycloak_namespace="$KEYCLOAK_NAMESPACE"                           \
         -D keycloak_ver="$KEYCLOAK_VER"                                       \
         -D kube_system_namespace="$KUBE_SYSTEM_NAMESPACE"                     \
         -D mesh_id="$MESH_ID"                                                 \
         -D multicluster_enabled="$MC_FLAG"                                    \
         -D netshoot_namespace="$NETSHOOT_NAMESPACE"                           \
         -D peering_discover_suffix="$PEERING_DISCOVERY_SUFFIX"                \
         -D prometheus_enabled="$PROMETHEUS_FLAG"                              \
         -D ratelimiter_enabled="$RATELIMITER_FLAG"                            \
         -D region="$_region"                                                  \
         -D sidecar_enabled="$SIDECAR_FLAG"                                    \
         -D sidecar_injector_webhooks_enabled="$SIDECAR_INJECTOR_WEBHOOKS_FLAG" \
         -D spire_enabled="$SPIRE_FLAG"                                        \
         -D spire_namespace="$SPIRE_NAMESPACE"                                 \
         -D spire_secret="$SPIRE_SECRET"                                       \
         -D tldn="$TLDN"                                                       \
         -D tls_termination_enabled="$TLS_TERMINATION_FLAG"                    \
         -D traffic_policy="$TRAFFIC_POLICY"                                   \
         -D utils_namespace="$UTILS_NAMESPACE"                                 \
         "$TEMPLATES"/jinja2_globals.yaml.j2                                   \
    >> "$J2_GLOBALS"
}
# END
