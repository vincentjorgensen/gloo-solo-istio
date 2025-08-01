#!/usr/bin/env bash
function app_init_istio_gateway {
  if $ISTIO_GATEWAY_ENABLED; then
    exec_istio_ingressgateway

    # EastWest linking via Istio Gateway
    if $MULTICLUSTER_ENABLED; then
      exec_eastwest_istio_gateway
      gsi_cluster_swap
      exec_eastwest_istio_gateway
      ! $GME_ENABLED && exec_eastwest_istio_oss_remote_secrets
      exec_gsi_cluster_swap
      ! $GME_ENABLED && exec_eastwest_istio_oss_remote_secrets
    fi
  fi
}
function exec_istio_ingressgateway {
  local _manifest="$MANIFESTS/helm.istio-ingressgateway.${GSI_CLUSTER}.yaml"

  if is_create_mode; then
    jinja2 -D size="${INGRESS_SIZE:-1}"                                       \
           -D network="$GSI_NETWORK"                                          \
           -D revision="$REVISION"                                            \
           -D istio_repo="$ISTIO_REPO"                                        \
           -D istio_ver="$ISTIO_VER"                                          \
           -D flavor="$ISTIO_FLAVOR"                                          \
           -D azure="$AZURE_FLAG"                                             \
           -D aws="$AWS_FLAG"                                                 \
           "$TEMPLATES"/helm.istio-ingressgateway.yaml.j2                     \
      > "$_manifest"

    $DRY_RUN helm upgrade -i istio-ingressgateway "$HELM_REPO"/gateway        \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$INGRESS_NAMESPACE"                                          \
    --create-namespace                                                        \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall istio-ingressgateway                              \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$INGRESS_NAMESPACE"
  fi
}

function exec_eastwest_istio_gateway {
  local _manifest="$MANIFESTS/helm.istio-eastwestgateway.${GSI_CLUSTER}.yaml"

  if is_create_mode; then
    jinja2 -D size="${GSI_EW_SIZE:-1}"                                        \
           -D network="$GSI_NETWORK"                                          \
           -D revision="$REVISION"                                            \
           -D istio_repo="$ISTIO_REPO"                                        \
           -D istio_ver="$ISTIO_VER"                                          \
           -D flavor="$ISTIO_FLAVOR"                                          \
           -D azure="$AZURE_FLAG"                                             \
           -D aws="$AWS_FLAG"                                                 \
           "$TEMPLATES"/helm.istio-eastwestgateway.yaml.j2                    \
      > "$_manifest"

    $DRY_RUN helm upgrade -i istio-eastwestgateway "$HELM_REPO"/gateway       \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$EASTWEST_NAMESPACE"                                         \
    --create-namespace                                                        \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall istio-eastwestgateway                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$EASTWEST_NAMESPACE"
  fi

  # OSS Expose Services
  if ! "$GME_ENABLED"; then
    cp "$TEMPLATES"/istio.eastwestgateway.cross-network-gateway.manifest.yaml \
       "$MANIFESTS"/istio.eastwestgateway.cross-network-gateway."$GSI_CLUSTER".yaml

    $DRY_RUN kubectl "$GSI_MODE"                                              \
    --context "$GSI_CONTEXT"                                                  \
    -f "$MANIFESTS"/istio.eastwestgateway.cross-network-gateway."$GSI_CLUSTER".yaml
  fi
}

function exec_eastwest_istio_oss_remote_secrets {
  # For K3D, Kind, and Rancher clusters
  if "$DOCKER_DESKTOP_ENABLED"; then
    istioctl-"${ISTIO_VER/-*/}" create-remote-secret                          \
    --context "$GSI_REMOTE_CONTEXT"                                           \
    --name "$GSI_REMOTE_CLUSTER"                                              \
    --server https://"$($DRY_RUN kubectl --context "$GSI_REMOTE_CONTEXT" get nodes -l node-role.kubernetes.io/control-plane=true -o jsonpath='{.items[0].status.addresses[0].address}')":6443 |
    $DRY_RUN kubectl "$GSI_MODE" -f - --context="$GSI_CONTEXT"
  # For AWS and Azure (and GCP?) clusters
  else
    istioctl-"${ISTIO_VER/-*/}" create-remote-secret                          \
    --context "$GSI_REMOTE_CONTEXT"                                           \
    --name "$GSI_REMOTE_CLUSTER"                                              |
    $DRY_RUN kubectl "$GSI_MODE" -f - --context="$GSI_CONTEXT"
  fi
}

function check_remote_cluster_status {
  local _cluster1 _cluster2
  _cluster1=$1
  _cluster2=$2

  istioctl-"${ISTIO_VER}" remote-clusters --context "$_cluster1"
  istioctl-"${ISTIO_VER}" remote-clusters --context "$_cluster2"
}

function exec_istio_vs_and_gateway {
  local _manifest="$MANIFESTS/istio.vs_and_gateway.${GSI_CLUSTER}.yaml"

  jinja2 -D name="$GSI_APP_SERVICE_NAME"                                      \
         -D namespace="$GSI_APP_SERVICE_NAMESPACE"                            \
         -D service_name="$GSI_APP_SERVICE_NAME"                              \
         -D service_port="$GSI_APP_SERVICE_PORT"                              \
         -D tldn="$TLDN"                                                      \
         -D gme_enabled="$GME_FLAG"                                           \
         -D cert_manager_enabled="$CERT_MANAGER_FLAG"                         \
         -D secret_name="$GSI_APP_GATEWAY_SECRET"                             \
       "$TEMPLATES"/istio.vs_and_gateway.manifest.yaml.j2                     \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}
