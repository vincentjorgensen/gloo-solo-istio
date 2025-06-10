#!/usr/bin/env bash
###############################################################################
# installs.sh
#
#
###############################################################################
export KGATEWAY_VER=v1.2.1
export TEMPLATES
TEMPLATES="$(dirname "$0")"/templates

function create_namespace {
  local _context _namespace
  _context=$1
  _namespace=$2

  kubectl create namespace "$_namespace"                                      \
    --context="$_context"
}

function delete_namespace {
  local _context _namespace
  _context=$1
  _namespace=$2

  kubectl delete namespace "$_namespace"                                      \
    --context="$_context"
}

function install_istio_secrets {
  local _cluster _context _namespace
  _cluster=$1
  _context=$2
  _namespace=$3

  kubectl create secret generic cacerts                                       \
    --context="$_context"                                                     \
    --namespace "$_namespace"                                                 \
    --from-file="$K3D_DIR"/certs/"${_cluster}"/ca-cert.pem                    \
    --from-file="$K3D_DIR"/certs/"${_cluster}"/ca-key.pem                     \
    --from-file="$K3D_DIR"/certs/"${_cluster}"/root-cert.pem                  \
    --from-file="$K3D_DIR"/certs/"${_cluster}"/cert-chain.pem
}

function uninstall_istio_secrets {
  local _cluster _context _namespace
  _cluster=$1
  _context=$2
  _namespace=$3

  kubectl delete secret cacerts                                               \
    --context="$_context"                                                     \
    --namespace "$_namespace"
}

function install_kgateway_crds {
  local _context
  _context=$1

  kubectl apply                                                               \
    --context="$_context"                                                     \
    -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"$KGATEWAY_VER"/standard-install.yaml
}

function uninstall_kgateway_crds {
  local _context
  _context=$1

  kubectl delete                                                              \
    --context="$_context"                                                     \
    -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"$KGATEWAY_VER"/standard-install.yaml
}

function install_istio_sidecar {
  local _cluster _context _network

  while getopts "c:w:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c) 
        _cluster=$OPTARG ;;
      w)
        _network=$OPTARG ;;
      x) 
        _context=$OPTARG ;;
    esac
  done

  [[ -z $_network ]] && _network="$_cluster"
  [[ -z $_context ]] && _context="$_cluster"

  kubectl label namespace istio-system topology.istio.io/network="$_network"  \
    --context "$_context" --overwrite

  # shellcheck disable=SC2086
  helm upgrade --install istio-base "$HELM_REPO"/base                         \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-system                                                  \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D revision="$REVISION"                                        \
               "$TEMPLATES"/istio-base.helm.values.yaml.j2 )                  \
    --wait

  helm upgrade --install istiod "$HELM_REPO"/istiod                           \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-system                                                  \
    --values <(jinja2                                                         \
               -D sidecar="enabled"                                           \
               -D cluster_name="$_cluster"                                    \
               -D revision="$REVISION"                                        \
               -D network="$_network"                                         \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D trust_domain="$TRUST_DOMAIN"                                \
               -D mesh_id="$MESH_ID"                                          \
               -D flavor="$ISTIO_FLAVOR"                                      \
               "$TEMPLATES"/istiod.helm.values.yaml.j2 )                      \
    --wait

  kubectl apply                                                               \
    --context "$_context"                                                     \
    -f "$TEMPLATES"/telemetry.istio-system.manifest.yaml
}

function uninstall_istio_sidecar {
  local _context
  _context=$1

  kubectl delete telemetry/mesh-default                                       \
    --context "$_context"                                                     \
    --namespace istio-system

  helm uninstall istiod istio-base                                            \
    --kube-context="$_context"                                                \
    --namespace istio-system
}

function install_istio_ambient {
  local _cluster _context _network

  while getopts "c:w:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c) 
        _cluster=$OPTARG ;;
      w)
        _network=$OPTARG ;;
      x) 
        _context=$OPTARG ;;
    esac
  done

  [[ -z $_network ]] && _network="$_cluster"
  [[ -z $_context ]] && _context="$_cluster"

  # Is this needed in ambient
  kubectl label namespace istio-system topology.istio.io/network="$_network"  \
    --context "$_context" --overwrite

  helm upgrade --install istio-base "$HELM_REPO"/base                         \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-system                                                  \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D revision="$REVISION"                                        \
               "$TEMPLATES"/istio-base.helm.values.yaml.j2 )                  \
    --wait

  helm upgrade --install istiod "$HELM_REPO"/istiod                           \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-system                                                  \
    --values <(jinja2                                                         \
               -D ambient="enabled"                                           \
               -D cluster_name="$_cluster"                                    \
               -D revision="$REVISION"                                        \
               -D network="$_network"                                         \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D trust_domain="$TRUST_DOMAIN"                                \
               -D mesh_id="$MESH_ID"                                          \
               -D flavor="$ISTIO_FLAVOR"                                      \
               -D license_key="$GLOO_MESH_LICENSE_KEY"                        \
               "$TEMPLATES"/istiod.helm.values.yaml.j2 )                      \
    --wait

  helm upgrade --install istio-cni "$HELM_REPO"/cni                           \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-system                                                  \
    --values <(jinja2                                                         \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               "$TEMPLATES"/istio-cni.helm.values.yaml.j2 )                   \
    --wait

  helm upgrade --install ztunnel "$HELM_REPO"/ztunnel                         \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-system                                                  \
    --values <(jinja2                                                         \
               -D cluster="$_cluster"                                         \
               -D network="$_network"                                         \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               "$TEMPLATES"/ztunnel.helm.values.yaml.j2 )                     \
    --wait

  kubectl apply                                                               \
    --context "$_context"                                                     \
    -f "$TEMPLATES"/telemetry.istio-system.manifest.yaml
}

function uninstall_istio_ambient {
  local _context
  _context=$1

  kubectl delete telemetry/mesh-default                                       \
    --context "$_context"                                                     \
    --namespace istio-system

  helm uninstall ztunnel istio-cni istiod istio-base                          \
    --kube-context="$_context"                                                \
    --namespace istio-system
}

function install_kgateway_eastwest {
  local _context _network _size _istio_126
  _context=$1
  _network=$2
  _size=${3:-1}

  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 26 ]]; then
    _istio_126="enabled"
  fi

  kubectl apply                                                               \
    --context "$_context"                                                     \
    -f <(jinja2                                                               \
         -D network="$_network"                                               \
         -D revision="$REVISION"                                              \
         -D size="$_size"                                                     \
         -D istio_126="$_istio_126"                                           \
         "$TEMPLATES"/kgateway.eastwest_gateway.template.yaml.j2 )
}

function uninstall_kgateway_eastwest {
  local _context
  _context=$1

  kubectl delete gateways.gateway.networking.k8s.io/istio-eastwest            \
    --context "$_context" --namespace istio-eastwest

  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 26 ]]; then
    kubectl delete configmap/istio-eastwest-options                           \
      --context "$_context" --namespace istio-eastwest
  fi
}

function install_kgateway_ew_link {
  local _context1 _cluster1 _network1 _context2 _remote_address _address_type
  _context1=$1
  _cluster1=$2
  _network1=$3
  _context2=$4

  _remote_address=$(
      kubectl get svc -n istio-eastwest istio-eastwest                        \
        --context "$_context1"                                                \
        -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  if echo "$_remote_address" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
    _address_type=IPAddress
  else
    _address_type=Hostname
  fi

  kubectl apply                                                               \
    --context "$_context2"                                                    \
    -f <(jinja2                                                               \
         -D trust_domain="$TRUST_DOMAIN"                                      \
         -D network="$_network1"                                              \
         -D cluster="$_cluster1"                                              \
         -D address_type="$_address_type"                                     \
         -D remote_address="$_remote_address"                                 \
         "$TEMPLATES"/kgateway.eastwest_remote_gateway.template.yaml.j2 )
}

function uninstall_kgateway_ew_link {
  local _context2 _cluster1
  _context2=$1
  _cluster1=$2

  kubectl delete                                                              \
          gateways.gateway.networking.k8s.io/istio-remote-peer-"${_cluster1}" \
    --context "$_context2"                                                    \
    --namesapce istio-eastwest
}

function install_gloo_mgmt_server {
  local _cluster _context
  _cluster=$1
  _context=$2

  kubectl create namespace gloo-mesh                                          \
    --context="$_context"

  kubectl apply                                                               \
    --context="$_context"                                                     \
    -f -<<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: relay-token
  namespace: gloo-mesh
stringData:
  token: "$GME_SECRET_TOKEN"
EOF
  
  helm install gloo-platform-crds gloo-platform/gloo-platform-crds            \
    --version="$GME_VER"                                                      \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh                                                     \
    --create-namespace                                                        \
    --wait

  helm upgrade -i gloo-platform-mgmt gloo-platform/gloo-platform              \
    --version="$GME_VER"                                                      \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh                                                     \
    --values <(
        jinja2                                                                \
        -D cluster_name="$_cluster"                                           \
        -D verbose="false"                                                    \
        -D azure_enabled="false"                                              \
        -D analyzer_enabled="false"                                           \
        -D insights_enabled="false"                                           \
        -D gloo_platform_license_key="$GLOO_PLATFORM_LICENSE_KEY"             \
        "$TEMPLATES"/gloo-mgmt-server.helm.values.yaml.j2 )                   \
    --wait

  kubectl apply                                                               \
    --context "$_cluster"                                                     \
    -f -<<EOF
---
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: $_cluster
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
...
EOF
}

function uninstall_gloo_mgmt_server {
  local _context
  _context=$1

  kubectl delete kubernetescluster/"$_cluster"                                \
    --context "$_context"                                                     \
    --namespace gloo-mesh

  helm uninstall gloo-platform-mgmt gloo-platform-crds \
    --kube-context="$_context" \
    --namespace=gloo-mesh

  kubectl delete secret/relay-token                                           \
    --context "$_context"                                                     \
    --namespace gloo-mesh
}

function install_gloo_agent {
  local _cluster _context _mgmt_context
  _cluster=$1
  _context=$2
  _mgmt_context=$3

  kubectl create namespace gloo-mesh                                          \
    --context="$_context"

  GLOO_MESH_SERVER=$(kubectl get svc gloo-mesh-mgmt-server                    \
    --context "$_mgmt_context"                                                \
    --namespace gloo-mesh                                                     \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  GLOO_MESH_TELEMETRY_GATEWAY=$(kubectl get svc gloo-telemetry-gateway        \
    --context "$_mgmt_context"                                                \
    --namespace gloo-mesh                                                     \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  kubectl apply                                                               \
    --context="$_context"                                                     \
    -f -<<EOF
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: relay-token
  namespace: gloo-mesh
stringData:
  token: "$GME_SECRET_TOKEN"
...
EOF
  
  helm install gloo-platform-crds gloo-platform/gloo-platform-crds            \
    --version="$GME_VER"                                                      \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh                                                     \
    --create-namespace                                                        \
    --wait

  helm upgrade -i gloo-platform-agent gloo-platform/gloo-platform             \
    --version="$GME_VER"                                                      \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh                                                     \
    --values <(
        jinja2                                                                \
        -D cluster_name="$_cluster"                                           \
        -D verbose="false"                                                    \
        -D insights_enabled="false"                                           \
        -D gloo_platform_license_key="$GLOO_PLATFORM_LICENSE_KEY"             \
        -D gloo_mesh_server="$GLOO_MESH_SERVER"                               \
        -D gloo_mesh_telemetry_gateway="$GLOO_MESH_TELEMETRY_GATEWAY"         \
        "$TEMPLATES"/gloo-agent.helm.values.yaml.j2 )                         \
    --wait

  kubectl --context "$_mgmt_context" apply                                    \
    -f -<<EOF
---
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: $_cluster
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
...
EOF
}

function uninstall_gloo_agent {
  local _context
  _context=$1

  kubectl delete kubernetescluster/"$_cluster"                                \
    --context "$_context"                                                     \
    --namespace gloo-mesh

  helm uninstall gloo-platform-agent gloo-platform-crds                       \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh

  kubectl delete secret/relay-token                                           \
    --context "$_context"                                                     \
    --namespace gloo-mesh
}

function install_istio_ingressgateway {
  local _context _size _network
  _context=$1
  _network=$2
  _size=${3:-1}
  _azure=""

  #echo "_size=$_size"
  helm upgrade -i istio-ingressgateway "$HELM_REPO"/gateway                   \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-gateways                                                \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D size="$_size"                                               \
               -D network="$_network"                                         \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               "$TEMPLATES"/istio-ingressgateway.helm.values.yaml.j2 )        \
    --wait
}

function uninstall_istio_ingressgateway {
  local _context
  _context=$1

  helm uninstall istio-ingressgateway                                         \
    --kube-context="$_context"                                                \
    --namespace istio-gateways
}

function install_istio_eastwestgateway {
  local _context _size _network
  _context=$1
  _network=$2
  _size=${3:-1}

#  echo "_size=$_size"
  helm upgrade -i istio-eastwestgateway "$HELM_REPO"/gateway                  \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace istio-eastwest                                                \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D size="$_size"                                               \
               -D network="$_network"                                         \
               -D revision="$REVISION"                                        \
               -D istio_repo="$ISTIO_REPO"                                    \
               -D istio_ver="$ISTIO_VER"                                      \
               -D flavor="$ISTIO_FLAVOR"                                      \
               "$TEMPLATES"/istio-eastwestgateway.helm.values.yaml.j2 )       \
    --wait

  # Expose Services
  kubectl apply                                                               \
    --context "$_context"                                                     \
    -f -<<EOF
---
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: cross-network-gateway
  namespace: istio-system
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        number: 15443
        name: tls
        protocol: TLS
      tls:
        mode: AUTO_PASSTHROUGH
      hosts:
        - "*.local"
...
EOF
}

function uninstall_istio_eastwestgateway {
  local _context
  _context=$1

  helm uninstall istio-eastwestgateway                                        \
    --kube-context="$_context"                                                \
    --namespace istio-gateways

}

function install_mutual_remote_secrets {
  local _cluster1 _cluster2
  _cluster1=$1
  _cluster2=$2

# For K3D local clusters
  if [[ "$_cluster1" =~ cluster ]]; then
    istioctl-"${ISTIO_VER}" create-remote-secret                              \
      --context="$_cluster1"                                                  \
      --name="$_cluster1"                                                     \
      --server https://"$(kubectl --context "$_cluster1" get nodes "k3d-${_cluster1}-server-0" -o jsonpath='{.status.addresses[0].address}')":6443 |
        kubectl apply -f - --context="${_cluster2}"
  
    istioctl-"${ISTIO_VER}" create-remote-secret                              \
      --context="$_cluster2"                                                  \
      --name="$_cluster2"                                                     \
      --server https://"$(kubectl --context "$_cluster2" get nodes "k3d-${_cluster2}-server-0" -o jsonpath='{.status.addresses[0].address}')":6443 |
        kubectl apply -f - --context="${_cluster1}"
  # For AWS and Azure (and GCP?) clusters
  else
    istioctl-"${ISTIO_VER}" create-remote-secret                              \
      --context="${_cluster1}"                                                \
      --name=cluster1                                                         |
        kubectl apply -f - --context="${_cluster2}"
  
    istioctl-"${ISTIO_VER}" create-remote-secret                              \
      --context="${_cluster2}"                                                \
      --name=cluster2                                                         |
        kubectl apply -f - --context="${_cluster1}"
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
             --context "$_context"                                            \
             -o yaml                                                          |
           yq '.items[].metadata.labels."topology.kubernetes.io/zone"'        |
           sort|uniq)

  echo "$_zones"
}

function install_helloworld_app {
  local _context _region _zones _ztemp _ambient _sidecar _size
  _sidecar=""
  _ambient=""
  _size=1
	_ztemp=$(mktemp)

  while getopts "ais:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      a)
        _ambient="enabled" ;;
      i) 
        _sidecar="enabled" ;;
      s) 
        _size=$OPTARG ;;
      x) 
        _context=$OPTARG ;;
    esac
  done

  _region=$(get_istio_region "$_context")

  _zones=$(kubectl get nodes                                                  \
    --context "$_context"                                                     \
    -o jsonpath='{.items[*].metadata.labels.topology\.kubernetes\.io/zone}')


  _zones=$(get_istio_zones "$_context")

  echo "zones:" > "$_ztemp"

  while read -r zone; do
    echo "- $zone" >> "$_ztemp"
  done <<< "$_zones"

  cp "$_ztemp" "$_ztemp".yaml

  kubectl apply                                                               \
    --context="$_context"                                                     \
    -f <(jinja2                                                               \
         -D region="$_region"                                                 \
         -D ambient_enabled="$_ambient"                                       \
         -D sidecar_enabled="$_sidecar"                                       \
         -D size="$_size"                                                     \
         -D revision="$REVISION"                                              \
         "$TEMPLATES"/helloworld.manifest.yaml.j2                             \
         "$_ztemp".yaml )
}

function install_curl_app {
  local _context _ambient _sidecar 
  _sidecar=""
  _ambient=""

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

  kubectl apply                                                               \
    --context="$_context"                                                     \
    -f <(jinja2                                                               \
         -D ambient_enabled="$_ambient"                                       \
         -D sidecar_enabled="$_sidecar"                                       \
         -D revision="$REVISION"                                              \
         "$TEMPLATES"/curl.template.yaml.j2 )
}

function install_tools_app {
  local _context _ambient _sidecar 
  _sidecar=""
  _ambient=""

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

  kubectl apply                                                               \
    --context="$_context"                                                     \
    -f <(jinja2                                                               \
         -D ambient_enabled="$_ambient"                                       \
         -D sidecar_enabled="$_sidecar"                                       \
         -D revision="$REVISION"                                              \
         "$TEMPLATES"/tools.template.yaml.j2 )
}

function install_istio_vs_and_gateway {
  local _context _port _tldn _name _namespace
  _context=$1
  _name=$2
  _namespace=$3
  _fqdn=$4
  _service_name=$5
  _service_port=$6

  kubectl apply                                                               \
    --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	      \
    -f <(jinja2                                                               \
         -D name="$_name"                                                     \
         -D namespace="$_namespace"                                           \
         -D fqdn="$_fqdn"                                                     \
         -D service_name="$_service_name"                                     \
         -D service_port="$_service_port"                                     \
       "$TEMPLATES"/istio.vs_and_gateway.template.yaml.j2 )
}

function install_kgateway_ingress_gateway {
  local _context _port _tldn _name _namespace _istio_126 _size
  _context=$1
  _name=$2
  _namespace=$3
  _tldn=$4
  _port=$5
  _size=${6:-1}

  if [[ $(echo "$ISTIO_VER" | awk -F. '{print $2}') -ge 26 ]]; then
    _istio_126="enabled"
  fi

  kubectl apply                                                               \
    --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	      \
    -f <(jinja2                                                               \
         -D revision="$REVISION"                                              \
         -D tldn="$_tldn"                                                     \
         -D port="$_port"                                                     \
         -D namespace="$_namespace"                                           \
         -D name="$_name"                                                     \
         -D size="$_size"                                                     \
         -D istio_126="$_istio_126"                                           \
       "$TEMPLATES"/kgateway.ingress_gateway.template.yaml.j2 )
}

function uninstall_kgateway_ingress_gateway {
  local _context _name _namespace
  _context=$1
  _name=$2
  _namespace=$3
  
  kubectl delete                                                              \
          gateways.gateway.networking.k8s.io/"$_name"                         \
    --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	        \
    --namespace "$_namespace"
}

function install_kgateway_httproute {
  local _context _gateway_name _fqdn _namespace
  local _service _service_namespace _service_port
  _context=$1
  _gateway_name=$2
  _namespace=$3
  _service=$4
  _service_namespace=$5
  _service_port=$6
  _fqdn=$7

  kubectl apply                                                       \
    --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
    -f <(jinja2                                                       \
         -D fqdn="$_fqdn"                                             \
         -D namespace="$_namespace"                                   \
         -D gateway_name="$_gateway_name"                             \
         -D service="$_service"                                       \
         -D service_namespace="$_service_namespace"                   \
         -D service_port="$_service_port"                             \
         "$TEMPLATES"/kgateway.httproute.template.yaml.j2 )
}

function uninstall_kgateway_httproute {
  local _context _gateway_name _fqdn _namespace
  local _service
  _context=$1
  _gateway_name=$2
  _namespace=$3
  _service=$4

  kubectl delete                                                      \
          httproutes.gateways.gateway.networking.k8s.io/"$_service"-route \
  --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
  --namespace "$_namespace"
}

function install_kgateway_reference_grant {
  local _context _gateway_namespace 
  local _service _service_namespace
  _context=$1
  _gateway_namespace=$2
  _service=$3
  _service_namespace=$4

  kubectl apply                                                       \
  --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
  -f <(jinja2                                                         \
       -D gateway_namespace="$_gateway_namespace"                     \
       -D service="$_service"                                         \
       -D service_namespace="$_service_namespace"                     \
       "$TEMPLATES"/kgateway.reference_grant.template.yaml.j2 )
}

function uninstall_kgateway_reference_grant {
  local _context _service _service_namespace
  _context=$1
  _service=$4
  _service_namespace=$5

  kubectl delete                                                      \
          referencegrants.gateways.gateway.networking.k8s.io/"$_service" \
  --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
  --namespace "$_service_namespace"
}

# END
