#!/usr/bin/env bash
###############################################################################
# execs.sh
#
# like installs.sh, but every function takes care of its own destructor if 
# GSI_MODE is set to "delete"
###############################################################################
export KGATEWAY_VER=v1.2.1
export TEMPLATES CERTS
TEMPLATES="$(dirname "$0")"/templates
CERTS="$(dirname "$0")"/certs
SPIRE_CERTS="$(dirname "$0")"/spire-certs

function create_namespace {
  local _context _namespace
  _context=$1
  _namespace=$2

  kubectl "$GSI_MODE" namespace "$_namespace"                                 \
  --context "$_context"
}

function exec_istio_secrets {
  if [[ $GSI_MODE == create ]]; then
    kubectl "$GSI_MODE" secret generic "$ISTIO_SECRET"                        \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --from-file="$CERTS"/"$GSI_CLUSTER"/ca-cert.pem                           \
    --from-file="$CERTS"/"$GSI_CLUSTER"/ca-key.pem                            \
    --from-file="$CERTS"/"$GSI_CLUSTER"/root-cert.pem                         \
    --from-file="$CERTS"/"$GSI_CLUSTER"/cert-chain.pem
  else
    kubectl delete secret cacerts                                             \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_spire_secrets {
  if [[ $GSI_MODE == create ]]; then
    kubectl "$GSI_MODE" secret generic "$SPIRE_SECRET"                        \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$SPIRE_SERVER_NAMESPACE"                                     \
    --from-file=tls.crt="$SPIRE_CERTS"/"${GSI_CLUSTER}"/ca-cert.pem           \
    --from-file=tls.key="$SPIRE_CERTS"/"${GSI_CLUSTER}"/ca-key.pem            \
    --from-file=bundle.crt="$SPIRE_CERTS"/"${GSI_CLUSTER}"/cert-chain.pem
  else
    kubectl delete secret spiffe-upstream-cacacerts                           \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$SPIRE_SERVER_NAMESPACE"
  fi
}

function exec_k8s_gateway_crds {
  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"$KGATEWAY_VER"/standard-install.yaml
}

function exec_k8s_gateway_experimental_crds {
  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"$KGATEWAY_VER"/experimental-install.yaml
}

function exec_kgateway_crds {
  if [[ $GSI_MODE == create ]]; then
    # shellcheck disable=SC2086
    helm upgrade --install kgateway-crds "$KGATEWAY_CRDS_HELM_REPO"           \
    --version "$KGATEWAY_HELM_VER"                                            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"                                  \
    --wait
  else
    helm uninstall kgateway-crds                                              \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"
  fi
}

function exec_kgateway {
  if [[ $GSI_MODE == create ]]; then
    # shellcheck disable=SC2086
    helm upgrade --install kgateway "$KGATEWAY_HELM_REPO"                     \
    --version "$KGATEWAY_HELM_VER"                                            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"                                  \
    --wait
  else
    helm uninstall kgateway                                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"
  fi

  if [[ $GSI_MODE != delete ]]; then
    kubectl wait                                                              \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"                                  \
    --for=condition=Ready pods --all
  fi
}

function exec_spire_crds {
  if [[ $GSI_MODE == create ]]; then
    # shellcheck disable=SC2086
    helm upgrade --install spire-crds spire/spire-crds                        \
    --version "$SPIRE_CRDS_VER"                                               \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_SERVER_NAMESPACE"                                     \
    --wait
  else
    helm uninstall spire-crds                                                 \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_SERVER_NAMESPACE"
  fi
}

function exec_spire_server {
  if [[ $GSI_MODE == create ]]; then
    # shellcheck disable=SC2086
    helm upgrade --install spire spire/spire                                  \
    --version "$SPIRE_SERVER_VER"                                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_SERVER_NAMESPACE"                                     \
    --values <(jinja2                                                         \
               -D trust_domain="$TRUST_DOMAIN"                                \
               -D spire_secret="$SPIRE_SECRET"                                \
               "$TEMPLATES"/helm.spire.yaml.j2 )                              \
    --wait

    kubectl wait                                                              \
    --namespace "$SPIRE_SERVER_NAMESPACE"                                     \
    --for=condition=Ready pods --all
  else
    helm uninstall spire                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_SERVER_NAMESPACE"
  fi

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f "$TEMPLATES"/spire.cluster-id.manifest.yaml
}
function exec_istio_base {
  if [[ $GSI_MODE == create ]]; then
    # shellcheck disable=SC2086
    helm upgrade --install istio-base "$HELM_REPO"/base                       \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D revision="$REVISION"                                        \
               "$TEMPLATES"/helm.istio-base.yaml.j2 )                         \
    --wait
  else
    helm uninstall istio-base                                                 \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_istio_istiod {
  local _cluster _network _sidecar_enabled _ambient_enabled _spire_enabled
  _cluster=$GSI_CLUSTER
  _network=$GSI_NETWORK
  "$SIDECAR_ENABLED" && _sidecar_enabled=enabled
  "$AMBIENT_ENABLED" && _ambient_enabled=enabled
  "$SPIRE_ENABLED" && _spire_enabled=enabled
  "$MULTICLUSTER_ENABLED" && _mc_enabled=enabled

  if [[ $GSI_MODE == create ]]; then
    helm upgrade --install istiod "$HELM_REPO"/istiod                         \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --values <(jinja2                                                         \
               -D ambient="$_ambient_enabled"                                 \
               -D sidecar="$_sidecar_enabled"                                 \
               -D spire="$_spire_enabled"                                     \
               -D cluster_name="$_cluster"                                    \
               -D revision="$REVISION"                                        \
               -D network="$_network"                                         \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D trust_domain="$TRUST_DOMAIN"                                \
               -D mesh_id="$MESH_ID"                                          \
               -D flavor="$ISTIO_FLAVOR"                                      \
               -D license_key="$GLOO_MESH_LICENSE_KEY"                        \
               -D multicluster="$_mc_enabled"                                 \
               -D variant="$ISTIO_DISTRO"                                     \
               "$TEMPLATES"/helm.istiod.yaml.j2 )                             \
    --wait
  else
    helm uninstall istiod                                                     \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_istio_cni {
  if [[ $GSI_MODE == create ]]; then
    helm upgrade --install istio-cni "$HELM_REPO"/cni                         \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --values <(jinja2                                                         \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               -D variant="$ISTIO_DISTRO"                                     \
               "$TEMPLATES"/helm.istio-cni.yaml.j2 )                          \
    --wait
  else
    helm uninstall istio-cni                                                  \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_istio_ztunnel {
  local _cluster _network _spire_enabled
  _cluster=$GSI_CLUSTER
  _network=$GSI_NETWORK

  "$SPIRE_ENABLED" && _spire_enabled=enabled
  "$MULTICLUSTER_ENABLED" && _mc_enabled=enabled

  if [[ $GSI_MODE == create ]]; then
    helm upgrade --install ztunnel "$HELM_REPO"/ztunnel                       \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --values <(jinja2                                                         \
               -D cluster="$_cluster"                                         \
               -D network="$_network"                                         \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               -D spire="$_spire_enabled"                                     \
               -D multicluster="$_mc_enabled"                                 \
               -D variant="$ISTIO_DISTRO"                                     \
               "$TEMPLATES"/helm.ztunnel.yaml.j2 )                            \
    --wait
  else
    helm uninstall ztunnel                                                    \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_telemetry_defaults {
  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f "$TEMPLATES"/telemetry.istio-system.manifest.yaml
}

###function exec_istio_sidecar {
###  local _cluster _network
###  _cluster=$GSI_CLUSTER
###  _network=$GSI_NETWORK
###
###  kubectl label namespace "$ISTIO_SYSTEM_NAMESPACE" topology.istio.io/network="$_network"  \
###  --context "$GSI_CONTEXT" --overwrite
###
###  exec_istio_base
###  exec_istio_istiod
###}
###
###function exec_istio_ambient {
###  kubectl label namespace "$ISTIO_SYSTEM_NAMESPACE" topology.istio.io/network="$GSI_NETWORK"  \
###    --context "$GSI_CONTEXT" --overwrite
###
###  exec_istio_base
###  exec_istio_istiod
###  exec_istio_cni
###  exec_istio_ztunnel
###}
###
function exec_istio {
  local _k_label="=$GSI_NETWORK"

  if [[ $GSI_MODE == delete ]]; then
    _k_label="-"
  fi
    
  if $MULTICLUSTER_ENABLED; then
    kubectl label namespace "$ISTIO_SYSTEM_NAMESPACE" "topology.istio.io/network${_k_label}"  \
    --context "$GSI_CONTEXT" --overwrite
  fi

  exec_istio_base
  exec_istio_istiod
  "$AMBIENT_ENABLED" && exec_istio_cni
  "$AMBIENT_ENABLED" && exec_istio_ztunnel

  if [[ $GSI_MODE != delete ]]; then
    kubectl wait                                                              \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --for=condition=Ready pods --all
  fi
}

function exec_kgateway_eastwest {
  local _istio_126

  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 26 ]]; then
    _istio_126="enabled"
  fi

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D network="$GSI_NETWORK"                                              \
       -D revision="$REVISION"                                                \
       -D size="$GSI_EW_SIZE"                                                 \
       -D istio_126="$_istio_126"                                             \
       "$TEMPLATES"/kgateway.eastwest_gateway.template.yaml.j2 )
}

function exec_kgateway_ew_link {
  local _remote_address _address_type

  _remote_address=$(
    kubectl get svc -n "$EASTWEST_NAMESPACE" istio-eastwest                   \
    --context "$GSI_CONTEXT_REMOTE"                                           \
    -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  while [[ -z $_remote_address ]]; do
    _remote_address=$(
      kubectl get svc -n "$EASTWEST_NAMESPACE" istio-eastwest                 \
      --context "$GSI_CONTEXT_REMOTE"                                         \
      -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
    echo -n '.' && sleep 5
  done && echo

  if echo "$_remote_address" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
    _address_type=IPAddress
  else
    _address_type=Hostname
  fi

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT_LOCAL"                                              \
  -f <(jinja2                                                                 \
       -D trust_domain="$TRUST_DOMAIN"                                        \
       -D network="$GSI_NETWORK_REMOTE"                                       \
       -D cluster="$GSI_CLUSTER_REMOTE"                                       \
       -D address_type="$_address_type"                                       \
       -D remote_address="$_remote_address"                                   \
       "$TEMPLATES"/kgateway.eastwest_remote_gateway.template.yaml.j2 )
}

function exec_gloo_mgmt_server {
  local _gloo_agent _aws_enabled _azure_enabled

  $AWS_ENABLED && _aws_enabled=enabled
  $AZURE_ENABLED && _azure_enabled=enabled

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D gme_secret_token="${GME_SECRET_TOKEN:-token}"                       \
       "$TEMPLATES"/gme.secret.relay-token.template.yaml.j2 )
  
  if [[ $GSI_MODE == create ]]; then
    helm install gloo-platform-crds gloo-platform/gloo-platform-crds          \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    --create-namespace                                                        \
    --wait

    helm upgrade -i gloo-platform-mgmt gloo-platform/gloo-platform            \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    --values <(jinja2                                                         \
          -D cluster_name="$GSI_CLUSTER"                                      \
          -D verbose="$GME_VERBOSE"                                           \
          -D azure_enabled="$_azure_enabled"                                  \
          -D aws_enabled="$_aws_enabled"                                      \
          -D analyzer_enabled="true"                                          \
          -D insights_enabled="true"                                          \
          -D gloo_agent="$_gloo_agent"                                        \
          -D gloo_platform_license_key="$GLOO_PLATFORM_LICENSE_KEY"           \
          "$TEMPLATES"/helm.gloo-mgmt-server.yaml.j2 )                        \
    --wait

    export GME_MGMT_CONTEXT=$GSI_CONTEXT
    export GME_MGMT_CLUSTER=$GSI_CLUSTER
  else
    helm uninstall gloo-platform-mgmt gloo-platform-crds                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"
  fi

}

function exec_gloo_k8s_cluster {
  kubectl "$GSI_MODE"                                                         \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f <(jinja2  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	  \
       -D cluster="$GSI_CLUSTER"                                              \
       "$TEMPLATES"/gloo.k8s_cluster.template.yaml.j2 )
}

function exec_gloo_agent {
  GLOO_MESH_SERVER=$(kubectl get svc gloo-mesh-mgmt-server                    \
    --context "$GME_MGMT_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  GLOO_MESH_TELEMETRY_GATEWAY=$(kubectl get svc gloo-telemetry-gateway        \
    --context "$GME_MGMT_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  kubectl "$GSI_MODE"                                                         \
    --context="$GSI_CONTEXT"                                                  \
    -f <(jinja2                                                               \
         -D gme_secret_token="${GME_SECRET_TOKEN:-token}"                     \
         "$TEMPLATES"/gme.secret.relay-token.template.yaml.j2 )
  
  if [[ $GSI_MODE == create ]]; then
    helm install gloo-platform-crds gloo-platform/gloo-platform-crds          \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    --create-namespace                                                        \
    --wait

    helm upgrade -i gloo-platform-agent gloo-platform/gloo-platform           \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    --values <(jinja2                                                         \
          -D cluster_name="$GSI_CLUSTER"                                      \
          -D verbose="$GME_VERBOSE"                                           \
          -D insights_enabled="true"                                          \
          -D analyzer_enabled="true"                                          \
          -D gloo_platform_license_key="$GLOO_PLATFORM_LICENSE_KEY"           \
          -D gloo_mesh_server="$GLOO_MESH_SERVER"                             \
          -D gloo_mesh_telemetry_gateway="$GLOO_MESH_TELEMETRY_GATEWAY"       \
          "$TEMPLATES"/helm.gloo-agent.yaml.j2 )                              \
      --wait
  else
    helm uninstall gloo-platform-agent gloo-platform-crds                     \
    --kube-context="$_context"                                                \
    --namespace="$GLOO_MESH_NAMESPACE"
  fi
}

function exec_istio_ingressgateway {
  local _azure_enabled _aws_enabled

  $AWS_ENABLED && _aws_enabled=enabled
  $AZURE_ENABLED && _azure_enabled=enabled

  if [[ $GSI_MODE == create ]]; then
    helm upgrade -i istio-ingressgateway "$HELM_REPO"/gateway                 \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$INGRESS_NAMESPACE"                                          \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D size="$GSI_INGRESS_SIZE"                                    \
               -D network="$GSI_NETWORK"                                      \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               -D azure="$_azure_enabled"                                     \
               -D aws="$_aws_enabled"                                         \
               "$TEMPLATES"/helm.istio-ingressgateway.yaml.j2 )               \
    --wait
  else
    helm uninstall istio-ingressgateway                                       \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$INGRESS_NAMESPACE"
  fi
}

function exec_istio_eastwest {
  local _aws_enabled _azure_enabled
  $AWS_ENABLED && _aws_enabled=enabled
  $AZURE_ENABLED && _azure_enabled=enabled

  if [[ $GSI_MODE == create ]]; then
    helm upgrade -i istio-eastwestgateway "$HELM_REPO"/gateway                \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$EASTWEST_NAMESPACE"                                         \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D size="${GSI_EW_SIZE:-1}"                                    \
               -D network="$GSI_NETWORK"                                      \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               -D azure="$_azure_enabled"                                     \
               -D aws="$_aws_enabled"                                         \
               "$TEMPLATES"/helm.istio-eastwestgateway.yaml.j2 )              \
    --wait
  else
    helm uninstall istio-eastwestgateway                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$EASTWEST_NAMESPACE"
  fi

  # OSS Expose Services
  if ! "$GME_ENABLED"; then
    kubectl "$GSI_MODE"                                                       \
    --context "$GSI_CONTEXT"                                                  \
    -f "$TEMPLATES"/istio.eastwestgateway.cross-network-gateway.manifest.yaml
  fi
}

function exec_oss_istio_remote_secrets {
  # For K3D, Kind, and Rancher clusters
  if "$DOCKER_DESKTOP_ENABLED"; then
    istioctl-"${ISTIO_VER/-*/}" create-remote-secret                          \
    --context "$GSI_CONTEXT_REMOTE"                                           \
    --name "$GSI_CLUSTER_REMOTE"                                              \
    --server https://"$(kubectl --context "$GSI_CONTEXT_REMOTE" get nodes -l node-role.kubernetes.io/control-plane=true -o jsonpath='{.items[0].status.addresses[0].address}')":6443 |
    kubectl "$GSI_MODE" -f - --context="$GSI_CONTEXT_LOCAL"
  # For AWS and Azure (and GCP?) clusters
  else
    istioctl-"${ISTIO_VER/-*/}" create-remote-secret                          \
    --context "$GSI_CONTEXT_REMOTE"                                           \
    --name "$GSI_CLUSTER_REMOTE"                                              \
    kubectl "$GSI_MODE" -f - --context="$GSI_CONTEXT_LOCAL"
  fi
}

function check_remote_cluster_status {
  local _cluster1 _cluster2
  _cluster1=$1
  _cluster2=$2

  istioctl-"${ISTIO_VER}" remote-clusters --context "$_cluster1"
  istioctl-"${ISTIO_VER}" remote-clusters --context "$_cluster2"
}

function get_istio_region {
  local _context
  _context=$1

  _region=$(kubectl get nodes                                                 \
    --context "$_context"                                                     \
    -o jsonpath='{.items[0].metadata.labels.topology\.kubernetes\.io/region}')

  echo "$_region"
}

function get_istio_zones {
  local _context
  _context=$1

  _zones=$(kubectl get nodes                                                  \
           --context "$_context"                                              \
           -o yaml                                                            |
           yq '.items[].metadata.labels."topology.kubernetes.io/zone"'        |
           sort|uniq)

  echo "$_zones"
}

function exec_helloworld_app {
  local _region _zones _ztemp _sidecar_enabled _ambient_enabled
  "$SIDECAR_ENABLED" && _sidecar_enabled=enabled
  "$AMBIENT_ENABLED" && _ambient_enabled=enabled
  
  # Traffic Distribution: PreferNetwork, PreferClose, PreferRegion, Any
	_ztemp=$(mktemp)

  _region=$(get_istio_region "$GSI_CONTEXT")

  _zones=$(get_istio_zones "$GSI_CONTEXT")

  echo "zones:" > "$_ztemp"

  while read -r zone; do
    echo "- $zone" >> "$_ztemp"
  done <<< "$_zones"

  cp "$_ztemp" "$_ztemp".yaml

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D region="$_region"                                                   \
       -D service_version="${GSI_SERVICE_VERSION:-none}"                      \
       -D ambient_enabled="$_ambient_enabled"                                 \
       -D traffic_distribution="${GSI_TRAFFIC_DISTRIBUTION:-Any}"             \
       -D sidecar_enabled="$_sidecar_enabled"                                 \
       -D size="${GSI_APP_SIZE:-1}"                                           \
       -D revision="$REVISION"                                                \
       -D namespace="$HELLOWORLD_NAMESPACE"                                   \
       -D service_port="$HELLOWORLD_SERVICE_PORT"                             \
       -D service_name="$HELLOWORLD_SERVICE_NAME"                             \
       "$TEMPLATES"/helloworld.template.yaml.j2                               \
       "$_ztemp".yaml )

  if [[ $GSI_MODE != delete ]]; then
    kubectl wait                                                              \
    --namespace "$HELLOWORLD_NAMESPACE"                                       \
    --for=condition=Ready pods --all
  fi
}

function exec_curl_app {
  local __sidecar_enabled _ambient_enabled
  "$SIDECAR_ENABLED" && _sidecar_enabled=enabled
  "$AMBIENT_ENABLED" && _ambient_enabled=enabled

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D ambient_enabled="$_ambient_enabled"                                 \
       -D sidecar_enabled="$_sidecar_enabled"                                 \
       -D namespace="$CURL_NAMESPACE"                                         \
       -D revision="$REVISION"                                                \
       "$TEMPLATES"/curl.manifest.yaml.j2 )

  if [[ $GSI_MODE != delete ]]; then
    kubectl wait                                                              \
    --namespace "$CURL_NAMESPACE"                                             \
    --for=condition=Ready pods --all
  fi
}

function exec_tools_app {
  local _ambient_enabled _sidecar_enabled
  "$SIDECAR_ENABLED" && _sidecar_enabled=enabled
  "$AMBIENT_ENABLED" && _ambient_enabled=enabled

  while getopts "aix:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      a)
        _ambient="enabled" ;;
      i) 
        _sidecar="enabled" ;;
      x) 
        _context=$OPTARG ;;
    esac
  done

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D ambient_enabled="$_ambient"                                         \
       -D sidecar_enabled="$_sidecar"                                         \
       -D revision="$REVISION"                                                \
       "$TEMPLATES"/tools.template.yaml.j2 )
}

function exec_istio_vs_and_gateway {
  local _gme_enabled
  $GME_ENABLED && _gme_enabled=enabled

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT" 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	        \
  -f <(jinja2                                                                 \
       -D name="$GSI_APP_SERVICE_NAME"                                        \
       -D namespace="$GSI_APP_SERVICE_NAMESPACE"                              \
       -D service_name="$GSI_APP_SERVICE_NAME"                                \
       -D service_port="$GSI_APP_SERVICE_PORT"                                \
       -D tldn="$TLDN"                                                        \
       -D gme_enabled="$_gme_enabled"                                         \
       "$TEMPLATES"/istio.vs_and_gateway.template.yaml.j2 )
}

function exec_istio_ingressgateway_no_helm {
  local _istio_126

  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 26 ]]; then
    _istio_126="enabled"
  fi

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT" 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	        \
  -f <(jinja2                                                                 \
       -D revision="$REVISION"                                                \
       -D port="$HTTP_INGRESS_PORT"                                           \
       -D namespace="$INGRESS_NAMESPACE"                                      \
       -D name="$INGRESS_GATEWAY_NAME"                                        \
       -D size="${GSI_INGRESS_SIZE:-1}"                                       \
       -D istio_126="$_istio_126"                                             \
       -D tldn="$TLDN"                                                        \
     "$TEMPLATES"/istio.ingress_gateway.template.yaml.j2 )
}

function exec_kgateway_ingressgateway {
  local _istio_126

  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 26 ]]; then
    _istio_126="enabled"
  fi

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT" 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	        \
  -f <(jinja2                                                                 \
       -D port="$HTTP_INGRESS_PORT"                                           \
       -D namespace="$INGRESS_NAMESPACE"                                      \
       -D name="$INGRESS_GATEWAY_NAME"                                        \
       -D gateway_class_name="kgateway"                                       \
       -D size="${GSI_INGRESS_SIZE:-1}"                                       \
       -D istio_126="$_istio_126"                                             \
       -D tldn="$TLDN"                                                        \
     "$TEMPLATES"/gateway_api.ingress_gateway.manifest.yaml.j2 )
}

function exec_httproute {
  local _mc_enabled
  "$MULTICLUSTER_ENABLED" && _mc_enabled=enabled

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D tldn="$TLDN"                                                        \
       -D namespace="$INGRESS_NAMESPACE"                                      \
       -D gateway_name="$INGRESS_GATEWAY_NAME"                                \
       -D gateway_namespace="$INGRESS_NAMESPACE"                              \
       -D service="$GSI_APP_SERVICE_NAME"                                     \
       -D service_namespace="$GSI_APP_SERVICE_NAMESPACE"                      \
       -D service_port="$GSI_APP_SERVICE_PORT"                                \
       -D multicluster="$_mc_enabled"                                         \
       "$TEMPLATES"/httproute.template.yaml.j2 )
}

function exec_kgateway_httproute {
  local _mc_enabled
  "$MULTICLUSTER_ENABLED" && _mc_enabled=enabled

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D tldn="$TLDN"                                                        \
       -D namespace="$GSI_APP_SERVICE_NAMESPACE"                              \
       -D gateway_name="$INGRESS_GATEWAY_NAME"                                \
       -D gateway_namespace="$KGATEWAY_SYSTEM_NAME"                           \
       -D service="$GSI_APP_SERVICE_NAME"                                     \
       -D service_namespace="$GSI_APP_SERVICE_NAMESPACE"                      \
       -D service_port="$GSI_APP_SERVICE_PORT"                                \
       -D multicluster="$_mc_enabled"                                         \
       "$TEMPLATES"/httproute.template.yaml.j2 )
}

function exec_reference_grant {
  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D gateway_namespace="$INGRESS_NAMESPACE"                              \
       -D service="$GSI_APP_SERVICE_NAME"                                     \
       -D service_namespace="$GSI_APP_SERVICE_NAMESPACE"                      \
       "$TEMPLATES"/kgateway.reference_grant.template.yaml.j2 )
}

function exec_tls_cert_secret {
  local _cluster _namespace _secret_name _context

  while getopts "c:n:s:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _cluster=$OPTARG ;;
      n)
        _namespace=$OPTARG ;;
      s)
        _secret_name=$OPTARG ;;
      x)
        _context=$OPTARG ;;
    esac
  done

  [[ -z $_context ]] && _context="$_cluster"

  if [[ $GSI_MODE == create ]]; then
    kubectl "$GSI_MODE" secret tls "$_secret_name"                            \
    --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	        	\
    --namespace "$_namespace"                                                 \
    --cert="${CERTS}"/"${_cluster}"/ca-cert.pem                               \
    --key="${CERTS}"/"${_cluster}"/ca-key.pem
  else
    kubectl "$GSI_MODE" secret "$_secret_name"                                \
    --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	        	\
    --namespace "$_namespace"
  fi
}

function exec_argocd_server {
  local _context _cluster
  _cluster=$1
  _context=$2

  while getopts "c:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _cluster=$OPTARG ;;
      x)
        _context=$OPTARG ;;
    esac
  done

  [[ -z $_context ]] && _context="$_cluster"

  if [[ $GSI_MODE == create ]]; then
    helm upgrade --install argocd argo/argo-cd                                \
    --kube-context "$_context"                                                \
    --namespace "$ARGOCD_NAMESPACE"                                           \
    --create-namespace                                                        \
    --values <(jinja2  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
               -D cluster="$_cluster"                                         \
               -D tldn="$TLDN"                                                \
               "$TEMPLATES"/helm.argocd.yaml.j2 )                             \
    --wait
  else
    helm uninstall argocd                                                     \
    --kube-context "$_context"                                                \
    --namespace "$ARGOCD_NAMESPACE"
  fi
}

function exec_argocd_cluster {
  local _argo_context _cluster _cluster_server _cert_data _key_data _ca_data
  local _context _k8s_user _k8s_cluster
  _cluster=$1
  _context=$2
  _argo_context=$3

  if [[ $(kubectl config get-contexts "$_context" --no-headers=true | awk '{print $1}') == '*' ]]; then
    _k8s_user=$(kubectl config get-contexts "$_context" --no-headers=true | awk '{print $4}')
    _k8s_cluster=$(kubectl config get-contexts "$_context" --no-headers=true | awk '{print $3}')
  else
    _k8s_user=$(kubectl config get-contexts "$_context" --no-headers=true | awk '{print $3}')
    _k8s_cluster=$(kubectl config get-contexts "$_context" --no-headers=true | awk '{print $2}')
  fi

  _cluster_server=https://"$(kubectl --context "$_context" get nodes "k3d-${_cluster}-server-0" -o jsonpath='{.status.addresses[0].address}')":6443

  _ca_data=$(
    kubectl config view                                                       \
    --raw=true                                                                \
    -o jsonpath='{.clusters[?(@.name == "'"$_k8s_cluster"'")].cluster.certificate-authority-data}')

  _cert_data=$(
    kubectl config view                                                       \
    --raw=true                                                                \
    -o jsonpath='{.users[?(@.name == "'"$_k8s_user"'")].user.client-certificate-data}')

  _key_data=$(
    kubectl config view                                                       \
    --raw=true                                                                \
    -o jsonpath='{.users[?(@.name == "'"$_k8s_user"'")].user.client-key-data}')

  kubectl "$GSI_MODE"                                                         \
  --context "$_argo_context"    	  	  	  	  	  	  	  	  	  	  	  	\
  -f <(jinja2  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	        \
       -D cluster="$_cluster"                                                 \
       -D cluster_server="$_cluster_server"                                   \
       -D cluster_server="$_cluster_server"                                   \
       -D cert_data="$_cert_data"                                             \
       -D key_data="$_key_data"                                               \
       -D ca_data="$_ca_data"                                                 \
      "$TEMPLATES"/argocd.secret.cluster.template.yaml.j2 )
}

function exec_external_dns_for_pihole {
  local _pihole_server_address

  _pihole_server_address=$(docker inspect pihole | jq -r '.[].NetworkSettings.Networks."'"$DOCKER_NETWORK"'".IPAddress')

  kubectl create secret generic pihole-password                               \
  --context "$GSI_CONTEXT"                                                    \
  --namespace "$KUBE_SYSTEM_NAMESPACE"                                        \
  --from-literal EXTERNAL_DNS_PIHOLE_PASSWORD="$(yq -r '.services.pihole.environment.FTLCONF_webserver_api_password' "$K3D_DIR"/pihole.docker-compose.yaml.j2)"

  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f <(jinja2                                                                 \
       -D pihole_server_address="$_pihole_server_address"                     \
       "$TEMPLATES"/externaldns.pihole.manifest.yaml.j2 )
}

function exec_gloo_workspace {
  local _ztemp
  _ztemp=$(mktemp)

  echo "namespaces:" >> "$_ztemp"
  for ns in "${GSI_WORKSPACE_NAMESPACES[@]}"; do
    echo "- $ns" >> "$_ztemp"
  done

  echo "workload_clusters:" >> "$_ztemp"
  for wc in "${GSI_WORKSPACE_CLUSTERS[@]}"; do
    echo "- $wc" >> "$_ztemp"
  done

  cp "$_ztemp" "$_ztemp".yaml

  kubectl "$GSI_MODE"                                                         \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f <(jinja2                                                                 \
       -D name="$GSI_WORKSPACE_NAME"                                          \
       -D namespace="$GLOO_MESH_NAMESPACE"                                    \
       -D mgmt_cluster="$GME_MGMT_CLUSTER"                                    \
       "$TEMPLATES"/gloo.workspace.manifest.yaml.j2                           \
       "$_ztemp".yaml )
}

function exec_gloo_workspacesettings {
  local _ztemp
  _ztemp=$(mktemp)

  echo "import_workspaces:" >> "$_ztemp"
  for ws in "${GSI_WORKSPACESETTTINGS_IMPORT_WORKSPACES[@]}"; do
    echo "- \"$ws\"" >> "$_ztemp"
  done

  echo "export_workspaces:" >> "$_ztemp"
  for ws in "${GSI_WORKSPACESETTTINGS_EXPORT_WORKSPACES[@]}"; do
    echo "- \"$ws\"" >> "$_ztemp"
  done

  cp "$_ztemp" "$_ztemp".yaml

  kubectl "$GSI_MODE"                                                         \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f <(jinja2                                                                 \
       -D name="$GSI_WORKSPACE_NAME"                                          \
       "$TEMPLATES"/gloo.workspacesettings.manifest.yaml.j2                   \
       "$_ztemp".yaml )
}

function exec_root_trust_policy {
  kubectl "$GSI_MODE"                                                         \
  --context "$GSI_CONTEXT"                                                    \
  -f "$TEMPLATES"/gloo.root-trust-policy.manifest.yaml
}

function exec_gloo_virtual_destination {
  kubectl "$GSI_MODE"                                                         \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f <(jinja2                                                                 \
       -D workspace="$GSI_WORKSPACE_NAME"                                     \
       -D app_service_name="$GSI_APP_SERVICE_NAME"                            \
       -D app_service_port="$GSI_APP_SERVICE_PORT"                            \
       -D tldn="$TLDN"                                                        \
       "$TEMPLATES"/gloo.virtualdestination.manifest.yaml.j2 )
}

function exec_gloo_route_table {
  kubectl "$GSI_MODE"                                                         \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f <(jinja2                                                                 \
       -D workspace="$GSI_WORKSPACE_NAME"                                     \
       -D app_service_name="$GSI_APP_SERVICE_NAME"                            \
       -D mgmt_cluster="$GME_MGMT_CLUSTER"                                    \
       -D tldn="$TLDN"                                                        \
       "$TEMPLATES"/gloo.routetable.manifest.yaml.j2 )
}

function exec_gloo_virtual_gateway {
  kubectl "$GSI_MODE"                                                         \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f <(jinja2                                                                 \
       -D gateways_workspace="$GME_GATEWAYS_WORKSPACE"                        \
       -D ingress_gateway_cluster_name="$GSI_GATEWAY_CLUSTER"                 \
       -D gateways_namespace="$INGRESS_NAMESPACE"                             \
       -D tldn="$TLDN"                                                        \
       "$TEMPLATES"/gloo.virtualgateway.manifest.yaml.j2 )
}

function exec_gsi_cluster_roll_forward {
  if [[ "$GSI_MODE" == create ]]; then
    export PREV_GSI_CLUSTER=$GSI_CLUSTER
    export PREV_GSI_CONTEXT=$GSI_CONTEXT
    export PREV_GSI_NETWORK=$GSI_NETWORK
  
    export GSI_CLUSTER=$NEXT_GSI_CLUSTER
    export GSI_CONTEXT=$NEXT_GSI_CONTEXT
    export GSI_NETWORK=$NEXT_GSI_NETWORK
  else
    export NEXT_GSI_CLUSTER=$GSI_CLUSTER
    export NEXT_GSI_CONTEXT=$GSI_CONTEXT
    export NEXT_GSI_NETWORK=$GSI_NETWORK
  
    export GSI_CLUSTER=$PREV_GSI_CLUSTER
    export GSI_CONTEXT=$PREV_GSI_CONTEXT
    export GSI_NETWORK=$PREV_GSI_NETWORK
  fi

  echo GSI_CLUSTER="$GSI_CLUSTER" GSI_CONTEXT="$GSI_CONTEXT" GSI_NETWORK="$GSI_NETWORK"
  echo PREV_GSI_CLUSTER="$PREV_GSI_CLUSTER" PREV_GSI_CONTEXT="$PREV_GSI_CONTEXT" PREV_GSI_NETWORK="$PREV_GSI_NETWORK"
  echo NEXT_GSI_CLUSTER="$NEXT_GSI_CLUSTER" NEXT_GSI_CONTEXT="$NEXT_GSI_CONTEXT" NEXT_GSI_NETWORK="$NEXT_GSI_NETWORK"
}

function exec_gsi_cluster_roll_back {
  if [[ "$GSI_MODE" == delete ]]; then
    export PREV_GSI_CLUSTER=$GSI_CLUSTER
    export PREV_GSI_CONTEXT=$GSI_CONTEXT
    export PREV_GSI_NETWORK=$GSI_NETWORK
  
    export GSI_CLUSTER=$NEXT_GSI_CLUSTER
    export GSI_CONTEXT=$NEXT_GSI_CONTEXT
    export GSI_NETWORK=$NEXT_GSI_NETWORK
  else
    export NEXT_GSI_CLUSTER=$GSI_CLUSTER
    export NEXT_GSI_CONTEXT=$GSI_CONTEXT
    export NEXT_GSI_NETWORK=$GSI_NETWORK
  
    export GSI_CLUSTER=$PREV_GSI_CLUSTER
    export GSI_CONTEXT=$PREV_GSI_CONTEXT
    export GSI_NETWORK=$PREV_GSI_NETWORK
  fi

  echo GSI_CLUSTER="$GSI_CLUSTER" GSI_CONTEXT="$GSI_CONTEXT" GSI_NETWORK="$GSI_NETWORK"
  echo PREV_GSI_CLUSTER="$PREV_GSI_CLUSTER" PREV_GSI_CONTEXT="$PREV_GSI_CONTEXT" PREV_GSI_NETWORK="$PREV_GSI_NETWORK"
  echo NEXT_GSI_CLUSTER="$NEXT_GSI_CLUSTER" NEXT_GSI_CONTEXT="$NEXT_GSI_CONTEXT" NEXT_GSI_NETWORK="$NEXT_GSI_NETWORK"
}
# END
