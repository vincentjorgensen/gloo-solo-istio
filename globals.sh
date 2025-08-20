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
export TEMPLATES CERTS MANIFESTS CERT_MANAGER_CERTS SPIRE_CERTS
TEMPLATES="$(dirname "$0")"/templates
CERTS="$(dirname "$0")"/certs
SPIRE_CERTS="$(dirname "$0")"/spire-certs
CERT_MANAGER_CERTS="$(dirname "$0")"/cert-manager/certs

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
export CURL_NAMESPACE=curl

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

#-------------------------------------------------------------------------------
# ArgoCD
#-------------------------------------------------------------------------------
export ARGOCD_ENABLED=${ARGOCD_ENABLED:-false}
export ARGOCD_VER="8.2.5"
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
# Gateway API
#-------------------------------------------------------------------------------
export EXPERIMENTAL_GATEWAY_API_CRDS=${EXPERIMENTAL_GATEWAY_API_CRDS:-false}
export GATEWAY_API_ENABLED=${GATEWAY_API_ENABLED:-false}

#-------------------------------------------------------------------------------
# Ingress Gateway Settings
#-------------------------------------------------------------------------------
export INGRESS_ENABLED=${INGRESS_ENABLED:-false}
export INGRESS_NAMESPACE=ingress-gateways
export INGRESS_GATEWAY=ingress-gateway
export INGRESS_HTTP_PORT=80
export INGRESS_HTTPS_PORT=443
export DEFAULT_TLDN=example.com
export TLDN=${TLDN:-$DEFAULT_TLDN}
export HTTP_FLAG HTTPS_FLAG INGRESS_GATEWAY_CLASS

#-------------------------------------------------------------------------------
# Eastwest Gateway Settings
#-------------------------------------------------------------------------------
export MULTICLUSTER_ENABLED=${MULTICLUSTER_ENABLED:-false}
export EASTWEST_NAMESPACE=eastwest-gateways
export EASTWEST_GATEWAY=eastwest-gateway
export MULTICLUSTER_NAMESPACE=$EASTWEST_NAMESPACE
export EASTWEST_SIZE=1
export EASTWEST_GATEWAY_CLASS MC_FLAG

#-------------------------------------------------------------------------------
# Ingress as Istio Gateway (OSS)
#-------------------------------------------------------------------------------
export ISTIO_GATEWAY_ENABLED=${ISTIO_GATEWAY_ENABLED:-false}
export TLS_TERMINATION_ENABLED=${TLS_TERMINATION_ENABLED:-false}
export TLS_TERMINATION_FLAG

#-------------------------------------------------------------------------------
# Ingress as KGateway
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
export GLOO_GATEWAY_ENABLED=${GLOO_GATEWAY_ENABLED:-false}
export GLOO_GATEWAY_NAMESPACE GLOO_GATEWAY_VER GLOO_GATEWAY_FLAG
export EXTAUTH_ENABLED=${EXTAUTH_ENABLED:-false}
export RATELIMITER_ENABLED=${RATELIMITER_ENABLED:-false}
export RATELIMITER_FLAG EXTAUTH_FLAG

#-------------------------------------------------------------------------------
# Ingress as Gloo Gateway (V1) (Edge or Gateway API)
#-------------------------------------------------------------------------------
export GLOO_GATEWAY_V1_ENABLED=${GLOO_GATEWAY_V1_ENABLED:-false}
export GLOO_GATEWAY_V1_NAMESPACE=gloo-system
export GLOO_GATEWAY_V1_VER=1.19.7
export GLOO_GATEWAY_V1_FLAG

#-------------------------------------------------------------------------------
# Ingress as Gloo Gateway V2 (Gateway API)
#-------------------------------------------------------------------------------
export GLOO_GATEWAY_V2_ENABLED=${GLOO_GATEWAY_V2_ENABLED:-false}
export GLOO_GATEWAY_V2_NAMESPACE=gloo-system
export GLOO_GATEWAY_V2_CRDS_HELM_REPO=oci://us-docker.pkg.dev/developers-369321/gloo-gateway-public-nonprod/charts/gloo-gateway-crds
export GLOO_GATEWAY_V2_HELM_REPO=oci://us-docker.pkg.dev/developers-369321/gloo-gateway-public-nonprod/charts/gloo-gateway
export GLOO_GATEWAY_V2_VER=2.0.0-alpha.4
export TRAFFIC_POLICY=oauth-authorization-code
export GLOO_GATEWAY_V2_FLAG

#-------------------------------------------------------------------------------
# Keycloak
#-------------------------------------------------------------------------------
export KEYCLOAK_ENABLED=${KEYCLOAK_ENABLED:-false}
export KEYCLOAK_NAMESPACE=keycloak
export KEYCLOAK_VER=26.3
export KEYCLOAK_ENDPOINT KEYCLOAK_HOST KEYCLOAK_PORT KEYCLOAK_URL
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
export HELM_REPO_127=oci://us-docker.pkg.dev/soloio-img/istio-helm
export ISTIO_REPO_127=us-docker.pkg.dev/soloio-img/istio
export ISTIO_VER_127=1.27.0
export ISTIO_SECRET=cacerts
export DEFAULT_MESH_ID="mesh"
export DEFAULT_TRUST_DOMAIN="cluster.local"
export TRUST_DOMAIN=${TRUST_DOMAIN:-$DEFAULT_TRUST_DOMAIN}
export MESH_ID=${MESH_ID:-$DEFAULT_MESH_ID}
export ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR ISTIO_DISTRO ISTIO_126_FLAG
export REVISION

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
export GME_VER_27="2.7.3"
export GME_VER_28="2.8.1"
export GME_VER_29="2.9.2"
export GME_VER_210="2.10.0"
export GME_GATEWAYS_WORKSPACE=gateways
export GME_APPLICATIONS_WORKSPACE=applications
export GME_VERBOSE=${GME_VERBOSE:-false}
export DEFAULT_GME="2.10"
export DEFAULT_GME_SECRET="relay-token"
export DEFAULT_GME_SECRET_TOKEN="my-lucky-secret-token"
export GME_SECRET=${GME_SECRET:-$DEFAULT_GME_SECRET}
export GME_SECRET_TOKEN=${GME_SECRET_TOKEN:-$DEFAULT_GME_SECRET_TOKEN}
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
export DEFAULT_GSI_MODE=create # create | apply | delete
export GSI_MODE=${GSI_MODE:-$DEFAULT_GSI_MODE}
export DRY_RUN=${DRY_RUN:-} # Testing and generating reproducible plans

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
  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 27 ]]; then
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
  $DOCKER_DESKTOP_ENABLED   && DOCKER_DESKTOP_FLAG=enabled   && echo '#' Docker Desktop is enabled
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
      EASTWEST_GATEWAY_CLASS=istio-eastwest
      echo '#' Ambient Multicluster is enabled
    fi
  fi

  # TLS Termination for istio gateway EW
  $TLS_TERMINATION_ENABLED && TLS_TERMINATION_FLAG=enabled
  
  # Kgateway (OSS)
  if $KGATEWAY_ENABLED; then
    KGATEWAY_FLAG=enabled
    INGRESS_GATEWAY_CLASS=kgateway
    INGRESS_ENABLED=true
    GATEWAY_API_ENABLED=true
    echo '#' Kgateway is enabled  on "$GSI_CLUSTER"
  fi

  if $GLOO_GATEWAY_V1_ENABLED; then
    GATEWAY_API_ENABLED=true
    GLOO_GATEWAY_V1_FLAG=enabled 
    GLOO_GATEWAY_FLAG=enabled 
    GLOO_GATEWAY_NAMESPACE=$GLOO_GATEWAY_V1_NAMESPACE 
    INGRESS_GATEWAY_CLASS=gloo-gateway
    INGRESS_ENABLED=true
    echo '#' Gloo Gateway V1 is enabled 
  fi

  # Gloo Gateway V2 (aka kgateway Enterprise)
  if $GLOO_GATEWAY_V2_ENABLED; then
    GATEWAY_API_ENABLED=true
    EXPERIMENTAL_GATEWAY_API_CRDS=true
    GLOO_GATEWAY_V2_FLAG=enabled 
    GLOO_GATEWAY_FLAG=enabled 
    GLOO_GATEWAY_NAMESPACE=$GLOO_GATEWAY_V2_NAMESPACE 
    INGRESS_GATEWAY_CLASS=gloo-gateway-v2
    INGRESS_ENABLED=true
    echo '#' Gloo Gateway V2 is enabled 
  fi

  # Spire
  $SPIRE_ENABLED && SPIRE_FLAG=enabled && echo '#' SPIRE is enabled

  # Cert-manager
  if $CERT_MANAGER_ENABLED; then
    CERT_MANAGER_FLAG=enabled 
    HTTPS_FLAG=enabled
    echo '#' Cert-manager is enabled
  fi

  # Keycloak and ExtAuth
  if $KEYCLOAK_ENABLED; then
    echo '#' Keycloak is enabled
    EXTAUTH_ENABLED=true && EXTAUTH_FLAG=enabled && echo '#' ExtAuth is enabled
    RATELIMITER_ENABLED=true && RATELIMITER_FLAG=enabled && echo '#' Rate-limiter is enabled
  fi

  if $AWS_ENABLED; then
    # shellcheck disable=SC2299
    COGNITO_ISSUER_FQDN="${${COGNITO_ISSUER_URL##*//}%%/*}"
  fi

  gsi_set_defaults
  _jinja2_values
}

function _get_k8s_region {
  local _context
  _context=$1

  _region=$(kubectl get nodes                                                 \
    --context "$_context"                                                     \
    -o jsonpath='{.items[0].metadata.labels.topology\.kubernetes\.io/region}')

  echo "$_region"
}

function _get_k8s_zones {
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

function _wait_for_pods {
  local _namespace=$1
  local _app=$2

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$_namespace"                                                 \
    --for=condition=Ready pods -l app="$_app"     
  fi
}

function _label_ns_for_istio {
  local _namespace=$1
  local _k_label _k_key

  if $AMBIENT_ENABLED; then
    local _k_label="=ambient"

    if ! is_create_mode; then
      _k_label="-"
    fi
    $DRY_RUN kubectl label namespace "$_namespace" "istio.io/dataplane-mode${_k_label}"  \
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
    $DRY_RUN kubectl label namespace "$_namespace" "${_k_key}${_k_label}"  \
    --context "$GSI_CONTEXT" --overwrite
  fi
}

function _jinja2_values {
  J2_GLOBALS="$MANIFESTS"/jinja2_globals.yaml

  _region=$(_get_k8s_region "$GSI_CONTEXT")
  _zones=$(_get_k8s_zones "$GSI_CONTEXT")

  echo "zones:" > "$J2_GLOBALS"

  while read -r zone; do
    echo "- $zone" >> "$J2_GLOBALS"
  done <<< "$_zones"

  jinja2                                                                      \
         -D ambient_enabled="$AMBIENT_FLAG"                                   \
         -D aws_enabled="$AWS_FLAG"                                           \
         -D cert_manager_enabled="$CERT_MANAGER_FLAG"                         \
         -D cert_manager_ingress_secret="$CERT_MANAGER_INGRESS_SECRET"        \
         -D cert_manager_namespace="$CERT_MANAGER_NAMESPACE"                  \
         -D cluster_issuer="$CLUSTER_ISSUER"                                  \
         -D cognito_issuer_fqdn="$COGNITO_ISSUER_FQDN"                        \
         -D cognito_issuer_url="$COGNITO_ISSUER"                              \
         -D cognito_jwt_route_option_name="$COGNITO_JWT_ROUTE_OPTION"         \
         -D cognito_keep_token_bool="$COGNITO_KEEP_TOKEN"                     \
         -D curl_namespace="$CURL_NAMESPACE"                                  \
         -D docker_desktop_enabled="$DOCKER_DESKTOP_ENABLED"                  \
         -D eastwest_gateway_class="$EASTWEST_GATEWAY_CLASS"                  \
         -D eastwest_gateway="$EASTWEST_GATEWAY"                              \
         -D eastwest_namespace="$EASTWEST_NAMESPACE"                          \
         -D eastwest_size="$EASTWEST_SIZE"                                    \
         -D extauth_enabled="$EXTAUTH_FLAG"                                   \
         -D gloo_gateway_enabled="$GLOO_GATEWAY_FLAG"                         \
         -D gloo_gateway_namespace="$GLOO_GATEWAY_NAMESPACE"                  \
         -D gloo_gateway_v1_enabled="$GLOO_GATEWAY_V1_FLAG"                   \
         -D gloo_gateway_v2_enabled="$GLOO_GATEWAY_V2_FLAG"                   \
         -D gme_namespace="$GME_NAMESPACE"                                    \
         -D helloworld_container_port="$HELLOWORLD_CONTAINER_PORT"            \
         -D helloworld_namespace="$HELLOWORLD_NAMESPACE"                      \
         -D helloworld_service_name="$HELLOWORLD_SERVICE_NAME"                \
         -D helloworld_service_port="$HELLOWORLD_SERVICE_PORT"                \
         -D helloworld_size="$HELLOWORLD_SIZE"                                \
         -D httpbin_container_port="$HTTPBIN_CONTAINER_PORT"                  \
         -D httpbin_namespace="$HTTPBIN_NAMESPACE"                            \
         -D httpbin_service_name="$HTTPBIN_SERVICE_NAME"                      \
         -D httpbin_service_port="$HTTPBIN_SERVICE_PORT"                      \
         -D httpbin_size="$HTTPBIN_SIZE"                                      \
         -D https_enabled="$HTTPS_FLAG"                                       \
         -D ingress_gateway_class="$INGRESS_GATEWAY_CLASS"                    \
         -D ingress_gateway="$INGRESS_GATEWAY"                                \
         -D ingress_http_port="$INGRESS_HTTP_PORT"                            \
         -D ingress_https_port="$INGRESS_HTTPS_PORT"                          \
         -D ingress_namespace="$INGRESS_NAMESPACE"                            \
         -D ingress_size="$INGRESS_SIZE"                                      \
         -D istio_126_enabled="$ISTIO_126_FLAG"                               \
         -D istio_flavor="$ISTIO_FLAVOR"                                      \
         -D istio_namespace="$ISTIO_NAMESPACE"                                \
         -D istio_repo="$ISTIO_REPO"                                          \
         -D istio_revision="$REVISION"                                        \
         -D istio_secret="$ISTIO_SECRET"                                      \
         -D istio_traffic_distribution="${TRAFFIC_DISTRIBUTION:-Any}"         \
         -D istio_variant="$ISTIO_DISTRO"                                     \
         -D istio_ver="$ISTIO_VER"                                            \
         -D keycloak_namespace="$KEYCLOAK_NAMESPACE"                          \
         -D keycloak_ver="$KEYCLOAK_VER"                                      \
         -D kube_system_namespace="$KUBE_SYSTEM_NAMESPACE"                    \
         -D license_key="$GLOO_MESH_LICENSE_KEY"                              \
         -D mesh_id="$MESH_ID"                                                \
         -D multicluster_enabled="$MC_FLAG"                                   \
         -D netshoot_namespace="$NETSHOOT_NAMESPACE"                          \
         -D ratelimiter_enabled="$RATELIMITER_FLAG"                           \
         -D region="$_region"                                                 \
         -D sidecar_enabled="$SIDECAR_FLAG"                                   \
         -D spire_enabled="$SPIRE_FLAG"                                       \
         -D spire_namespace="$SPIRE_NAMESPACE"                                \
         -D spire_secret="$SPIRE_SECRET"                                      \
         -D tldn="$TLDN"                                                      \
         -D traffic_policy="$TRAFFIC_POLICY"                                  \
         -D utils_namespace="$UTILS_NAMESPACE"                                \
         "$TEMPLATES"/jinja2_globals.yaml.j2                                  \
    >> "$J2_GLOBALS"
}
# END
