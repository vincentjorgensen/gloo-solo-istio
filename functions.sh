#!/usr/bin/env bash
###############################################################################
# GLOO SOLO ISTIO
#
# Common functions for manipulating Istio clusters, Gloo Platform, and Solo.io
# builds
###############################################################################
#-------------------------------------------------------------------------------
# Global versions of Helm Repos, Istio Repos, and Gateway API
#-------------------------------------------------------------------------------
export KGATEWAY_VER=v1.2.1

export GLOO_MESH_VERSION="2.9.0"

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
export ISTIO_VER_126=1.26.1

export GLOO_MESH_SECRET_TOKEN="my-lucky-secret-token" # arbitrary

export TEMPLATES REVISION ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR

TEMPLATES="$(dirname "$0")"/templates

function set_revision {
  local _revision
  _revision=$1

  export REVISION="$_revision"
}

function set_istio {
  local _istio
  _istio=$1

  export ISTIO_VER ISTIO_REPO HELM_REPO ISTIO_FLAVOR
  ISTIO_VER=$(eval echo \$ISTIO_VER_"${_istio//.}")
  ISTIO_REPO=$(eval echo \$ISTIO_REPO_"${_istio//.}")
  HELM_REPO=$(eval echo \$HELM_REPO_"${_istio//.}")
  ISTIO_FLAVOR="-solo"
}

function create_namespace {
  local _cluster _context _namespace
  _cluster=$1
  _context=$2
  _namespace=$3

  kubectl create namespace "$_namespace"                                      \
    --context="$_context"
}

function delete_namespace {
  local _cluster _context _namespace
  _cluster=$1
  _context=$2
  _namespace=$3

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
  local _cluster _context _network _mesh_id _trust_domain _crd_templates
  _cluster=$1
  _context=$2
  _network=$3
  _mesh_id=mesh
  _trust_domain=cluster.local

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
               -D trust_domain="$_trust_domain"                               \
               -D mesh_id="$_mesh_id"                                         \
               -D flavor="$ISTIO_FLAVOR"                                      \
               "$TEMPLATES"/istiod.helm.values.yaml.j2 )                      \
    --wait

  kubectl apply                                                               \
    --context "$_context"                                                     \
    -f "$TEMPLATES"/telemetry.istio-system.manifest.yaml
}

function uninstall_istio {
  local _context
  _context=$1

  helm uninstall istiod istio-base                                            \
    --kube-context="$_context"                                                \
    --namespace istio-system
}

function install_istio_ambient {
  local _cluster _context _network _mesh_id _trust_domain
  _mesh_id=mesh
  _trust_domain=cluster.local

  while getopts "c:m:t:w:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c) 
        _cluster=$OPTARG ;;
      m) 
        _mesh_id=$OPTARG ;;
      t) 
        _trust_domain=$OPTARG ;;
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

helm upgrade --install istiod "$HELM_REPO"/istiod                             \
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
               -D trust_domain="$_trust_domain"                               \
               -D mesh_id="$_mesh_id"                                         \
               -D flavor="$ISTIO_FLAVOR"                                      \
               -D license_key="$GLOO_MESH_LICENSE_KEY"                        \
               "$TEMPLATES"/istiod.helm.values.yaml.j2 )                      \
    --wait

helm upgrade --install istio-cni "$HELM_REPO"/cni                             \
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

helm upgrade --install ztunnel "$HELM_REPO"/ztunnel                           \
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

  helm uninstall ztunnel istio-cni istiod istio-base                          \
    --kube-context="$_context"                                                \
    --namespace istio-system

  kubectl delete secret cacerts                                               \
    --context="$_context"                                                     \
    --namespace istio-system
}

function install_kgateway_eastwest {
  local _context _size
  _context=$1
  _network=$2
  _size=${3:-1}

  kubectl apply                                                               \
    --context "$_context"                                                     \
    -f <(jinja2                                                               \
         -D network="$_network"                                               \
         -D revision="$REVISION"                                              \
         -D size="$_size"                                                     \
         "$TEMPLATES"/kgateway-eastwest.template.yaml.j2)
}

function install_kgateway_eastwest_126 {
  local _context _size
  _context=$1
  _network=$2
  _size=${3:-1}

  kubectl apply                                                               \
    --context "$_context"                                                     \
    -f <(jinja2                                                               \
         -D network="$_network"                                               \
         -D revision="$REVISION"                                              \
         -D size="$_size"                                                     \
         "$TEMPLATES"/kgateway-eastwest.126.template.yaml.j2)
}

function uninstall_kgateway_eastwest {
  local _context
  _context=$1

  kubectl delete gateways.gateway.networking.k8s.io/istio-eastwest            \
    --context "$_context" --namespace istio-eastwest
}

function install_kgateway_ew_link {
  local _context2 _cluster1 _remote_address _address_type

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

kubectl --context "$_context2" apply -f -<<EOF
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  annotations:
    gateway.istio.io/service-account: istio-eastwest
    gateway.istio.io/trust-domain: cluster.local
  labels:
    topology.istio.io/network: $_network1
  name: istio-remote-peer-${_cluster1}
  namespace: istio-eastwest
spec:
  addresses:
  - type: $_address_type
    value: $_remote_address
  gatewayClassName: istio-remote
  listeners:
  - name: cross-network
    port: 15008
    protocol: HBONE
    tls:
      mode: Passthrough
  - name: xds-tls
    port: 15012
    protocol: TLS
    tls:
      mode: Passthrough
...
EOF
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
  token: "$GLOO_MESH_SECRET_TOKEN"
EOF
  
  helm install gloo-platform-crds gloo-platform/gloo-platform-crds            \
    --version="$GLOO_MESH_VERSION"                                            \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh                                                     \
    --create-namespace                                                        \
    --wait

  helm upgrade -i gloo-platform-mgmt gloo-platform/gloo-platform              \
    --version=$GLOO_MESH_VERSION                                              \
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

  helm uninstall gloo-platform-mgmt gloo-platform-crds \
    --kube-context="$_context" \
    --namespace=gloo-mesh
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
  token: "$GLOO_MESH_SECRET_TOKEN"
...
EOF
  
  helm install gloo-platform-crds gloo-platform/gloo-platform-crds            \
    --version="$GLOO_MESH_VERSION"                                            \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh                                                     \
    --create-namespace                                                        \
    --wait

  helm upgrade -i gloo-platform-agent gloo-platform/gloo-platform             \
    --version=$GLOO_MESH_VERSION                                              \
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

  helm uninstall gloo-platform-agent gloo-platform-crds                       \
    --kube-context="$_context"                                                \
    --namespace=gloo-mesh
}

function install_istio_ingressgateway {
  local _context _size _network
  _context=$1
  _network=$2
  _size=${3:-1}
  _azure=""

  echo "_size=$_size"
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
  local _context _port _tldn _name _namespace
  _context=$1
  _name=$2
  _namespace=$3
  _tldn=$4
  _port=$5

  kubectl apply                                                               \
    --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	      \
    -f <(jinja2                                                               \
         -D revision="$REVISION"                                              \
         -D tldn="$_tldn"                                                     \
         -D port="$_port"                                                     \
         -D namespace="$_namespace"                                           \
         -D name="$_name"                                                     \
       "$TEMPLATES"/kgateway.ingress_gateway.template.yaml.j2 )
}

function uninstall_kgateway_ingress_gateway {
  local _context _name _namespace
  _context=$1
  _name=$2
  _namespace=$3
  
  kubectl delete                                                      \
          gateways.gateway.networking.k8s.io/"$_name"                 \
  --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
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
  --context "$_context"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
  -f <(jinja2                                                         \
       -D fqdn="$_fqdn"                                               \
       -D namespace="$_namespace"                                     \
       -D gateway_name="$_gateway_name"                               \
       -D service="$_service"                                         \
       -D service_namespace="$_service_namespace"                     \
       -D service_port="$_service_port"                               \
       "$TEMPLATES"/kgateway.httproute.template.yaml.j2)
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
  
deploy_istio_sidecar() {
  local _cluster
  _cluster=$1

  create_namespace "$_cluster" "$_cluster" istio-system
  install_istio_secrets "$_cluster" "$_cluster" istio-system
  install_istio_sidecar "$_cluster" "$_cluster" "$_cluster"
}

deploy_istio_ambient() {
  local _cluster _istio
  _cluster=$1

  create_namespace "$_cluster" "$_cluster" istio-system
  install_istio_secrets "$_cluster" "$_cluster" istio-system
  install_istio_ambient -c "$_cluster"
}

deploy_kgateway_eastwest() {
  local _cluster 
  _cluster=$1

  create_namespace "$_cluster" "$_cluster" istio-eastwest
  install_kgateway_eastwest_126 "$_cluster" "$_cluster"
}
