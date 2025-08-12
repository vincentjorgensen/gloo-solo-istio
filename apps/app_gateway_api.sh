#!/usr/bin/env bash
function app_init_gateway_api {
  if $GATEWAY_API_ENABLED; then 
    exec_gateway_api_crds 
    if $KGATEWAY_ENABLED; then
      exec_kgateway_crds
      exec_kgateway
    elif $GLOO_GATEWAY_V2_ENABLED; then
      exec_gloo_gateway_v2_crds
      exec_gloo_gateway_v2
    fi
    ### ### ### exec_ingress_gateway_api
  
    if $MULTICLUSTER_ENABLED; then
      gsi_cluster_swap

      exec_gateway_api_crds 
      if $KGATEWAY_ENABLED; then
        exec_kgateway_crds
        exec_kgateway
      elif $GLOO_GATEWAY_V2_ENABLED; then
        exec_gloo_gateway_v2_crds
        exec_gloo_gateway_v2
      fi

      gsi_cluster_swap
    fi
  fi
}

function app_init_ingress_gateway_api {
  if $GATEWAY_API_ENABLED; then 
    if $KEYCLOAK_ENABLED; then
      if $KGATEWAY_ENABLED; then
        exec_kgateway_keycloak_secret
      elif $GLOO_GATEWAY_V2_ENABLED; then
        exec_gloo_gateway_v2_keycloak_secret
      fi
    fi

    exec_ingress_gateway_api
  fi
}

function app_init_eastwest_gateway_api {
  if $GATEWAY_API_ENABLED; then 
    # EastWest linking via Gateway API
    if $MULTICLUSTER_ENABLED; then
      exec_gateway_api_crds
      exec_eastwest_gateway_api
      gsi_cluster_swap
      exec_gateway_api_crds
      exec_eastwest_gateway_api
      exec_eastwest_link_gateway_api
      gsi_cluster_swap
      exec_eastwest_link_gateway_api
    fi
  fi
}

function exec_gateway_api_crds {
  local _ver="$KGATEWAY_VER"
  local _standard=standard
  $EXPERIMENTAL_GATEWAY_API_CRDS && _ver="$KGATEWAY_EXPERIMENTAL_VER" && _standard=experimental

  if [[ -z $(eval echo '$'GATEWAY_API_CRDS_APPLIED_"${GSI_CLUSTER//-/_}") ]]; then
    $DRY_RUN kubectl "$GSI_MODE"                                              \
    --context "$GSI_CONTEXT"                                                  \
    -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"$_ver"/"${_standard}"-install.yaml
    [[ -z $DRY_RUN ]] && eval GATEWAY_API_CRDS_APPLIED_"${GSI_CLUSTER//-/_}"=applied
  fi

  if ! is_create_mode; then
    $DRY_RUN kubectl "$GSI_MODE"                                              \
    --context "$GSI_CONTEXT"                                                  \
    -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"$_ver"/"${_standard}"-install.yaml
    [[ -z $DRY_RUN ]] && eval unset GATEWAY_API_CRDS_APPLIED_"${GSI_CLUSTER//-/_}"
    
  fi
}

function exec_kgateway_crds {
  if is_create_mode; then
    # shellcheck disable=SC2086
    $DRY_RUN helm upgrade --install kgateway-crds "$KGATEWAY_CRDS_HELM_REPO"  \
    --version "$KGATEWAY_HELM_VER"                                            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"                                  \
    --wait
  else
    $DRY_RUN helm uninstall kgateway-crds                                     \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"
  fi
}

function exec_kgateway {
  local _k_label="=ambient"

  if ! is_create_mode; then
    _k_label="-"
  fi

  if $AMBIENT_ENABLED; then
    $DRY_RUN kubectl label namespace "$INGRESS_NAMESPACE" "istio.io/dataplane-mode${_k_label}"  \
    --context "$GSI_CONTEXT" --overwrite
  fi

  if is_create_mode; then
    # shellcheck disable=SC2086
    $DRY_RUN helm upgrade --install kgateway "$KGATEWAY_HELM_REPO"            \
    --version "$KGATEWAY_HELM_VER"                                            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"                                  \
    --wait
  else
    $DRY_RUN helm uninstall kgateway                                          \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"
  fi

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context="$GSI_CONTEXT"                                                  \
    --namespace "$KGATEWAY_SYSTEM_NAMESPACE"                                  \
    --for=condition=Ready pods --all
  fi
}

function exec_eastwest_gateway_api {
  local _manifest="$MANIFESTS/gateway_api.eastwest_gateway.${GSI_CLUSTER}.yaml"

  jinja2 -D network="$GSI_NETWORK"                                            \
         -D revision="$REVISION"                                              \
         -D size="$GSI_EW_SIZE"                                               \
         -D istio_126="$ISTIO_126_FLAG"                                       \
         -D name="$EASTWEST_GATEWAY_NAME"                                     \
         -D gateway_class_name="$EASTWEST_GATEWAY_CLASS_NAME"                 \
         -D namespace="$EASTWEST_NAMESPACE"                                   \
         "$TEMPLATES"/gateway_api.eastwest_gateway.manifest.yaml.j2           \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  sleep 1.5

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$EASTWEST_NAMESPACE"                                         \
    --for=condition=Ready pods -l app="$EASTWEST_GATEWAY_NAME"
  fi
}

function exec_eastwest_link_gateway_api {
  local _manifest="$MANIFESTS/gateway_api.eastwest_remote_gateway.${GSI_REMOTE_CLUSTER}.yaml"
  local _remote_address _address_type

  _remote_address=$(
    kubectl get svc "$EASTWEST_GATEWAY_NAME"                                  \
    --namespace "$EASTWEST_NAMESPACE"                                         \
    --context "$GSI_CONTEXT"                                                  \
    -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  if is_create_mode; then
  while [[ -z $_remote_address ]]; do
      _remote_address=$(
        $DRY_RUN kubectl get svc "$EASTWEST_GATEWAY_NAME"                       \
        --namespace "$EASTWEST_NAMESPACE"                                       \
        --context "$GSI_CONTEXT"                                                \
        -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
      echo -n '.' && sleep 5
    done && echo
  fi

  if echo "$_remote_address" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
    _address_type=IPAddress
  else
    _address_type=Hostname
  fi

  jinja2 -D trust_domain="$TRUST_DOMAIN"                                      \
         -D network="$GSI_NETWORK"                                            \
         -D cluster="$GSI_CLUSTER"                                            \
         -D name="$EASTWEST_GATEWAY_NAME"                                     \
         -D namespace="$EASTWEST_NAMESPACE"                                   \
         -D gateway_class_name="$EASTWEST_REMOTE_GATEWAY_CLASS_NAME"          \
         -D address_type="$_address_type"                                     \
         -D remote_address="$_remote_address"                                 \
         -D revision="$REVISION"                                              \
         "$TEMPLATES"/gateway_api.eastwest_remote_gateway.manifest.yaml.j2    \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_REMOTE_CONTEXT"                                             \
  -f "$_manifest"
}

function exec_ingress_gateway_api {
  local _manifest="$MANIFESTS/gateway_api.ingress_gateway.${GSI_CLUSTER}.yaml"

  jinja2 -D revision="$REVISION"                                              \
         -D port="$HTTP_INGRESS_PORT"                                         \
         -D ssl_port="$HTTPS_INGRESS_PORT"                                    \
         -D namespace="$INGRESS_NAMESPACE"                                    \
         -D name="$INGRESS_GATEWAY_NAME"                                      \
         -D gateway_class_name="$GATEWAY_CLASS_NAME"                          \
         -D size="${INGRESS_SIZE:-1}"                                         \
         -D istio_126="$ISTIO_126_FLAG"                                       \
         -D tldn="$TLDN"                                                      \
         -D cert_manager_enabled="$CERT_MANAGER_FLAG"                         \
         -D ratelimiter_enabled="$RATELIMITER_FLAG"                           \
         -D extauth_enabled="$EXTAUTH_FLAG"                                   \
         -D secret_name="$CERT_MANAGER_INGRESS_SECRET"                        \
        "$TEMPLATES"/gateway_api.ingress_gateway.manifest.yaml.j2             \
    > "$_manifest"

  if $GLOO_GATEWAY_V2_ENABLED; then
    patch_gloo_gateway_v2 "$INGRESS_NAMESPACE" "${INGRESS_GATEWAY_NAME}-ggw-params"
  fi

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}

function exec_gloo_gateway_v2_crds {
  if is_create_mode; then
    $DRY_RUN helm upgrade --install gloo-gateway-crds "$GLOO_GATEWAY_V2_CRDS_HELM_REPO" \
    --version "$GLOO_GATEWAY_V2_HELM_VER"                                     \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$GLOO_GATEWAY_V2_NAMESPACE"                                  \
    --create-namespace
  else 
    $DRY_RUN helm uninstall gloo-gateway-crds                                 \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$GLOO_GATEWAY_V2_NAMESPACE"
  fi
}

function exec_gloo_gateway_v2 {
  local _k_label="=ambient"

  if ! is_create_mode; then
    _k_label="-"
  fi

  if $AMBIENT_ENABLED; then
    $DRY_RUN kubectl label namespace "$INGRESS_NAMESPACE" "istio.io/dataplane-mode${_k_label}"  \
    --context "$GSI_CONTEXT" --overwrite
  fi

  if is_create_mode; then
    $DRY_RUN helm upgrade --install gloo-gateway "$GLOO_GATEWAY_V2_HELM_REPO" \
    --version "$GLOO_GATEWAY_V2_HELM_VER"                                     \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$GLOO_GATEWAY_V2_NAMESPACE"
  else 
    $DRY_RUN helm uninstall gloo-gateway                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$GLOO_GATEWAY_V2_NAMESPACE"
  fi

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context="$GSI_CONTEXT"                                                  \
    --namespace "$GLOO_GATEWAY_V2_NAMESPACE"                                  \
    --for=condition=Ready pods --all
  fi
}

function patch_gloo_gateway_v2 {
  local _namespace=$1
  local _name=$2
#  local _manifest="$MANIFESTS/gloo_gateway_parameters.${GSI_CLUSTER}.yaml"

##  jinja2 -D namespace="$_namespace"                                           \
##         -D name="$GLOO_GATEWAY_PARAMETERS_NAME"                              \
##         "$TEMPLATES"/gloo_gateway_parameters.manifest.yaml.j2                \
##    > "$_manifest"
##
##  $DRY_RUN kubectl "$GSI_MODE"                                                \
##  --context "$GSI_CONTEXT"                                                    \
##  -f "$_manifest" 

  if is_create_mode; then
   $DRY_RUN  kubectl patch gatewayclass gloo-gateway-v2                       \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$_namespace"                                                 \
    --type=merge                                                              \
    --patch='{
    "spec": {
      "parametersRef": {
        "group": "gloo.solo.io",
        "kind": "GlooGatewayParameters",
        "name": "'"$_name"'",
        "namespace": "'"$_namespace"'"
      } } }'
  fi
}

function exec_httproute {
  local _manifest="$MANIFESTS/httproute.${GSI_CLUSTER}.yaml"

  jinja2 -D tldn="$TLDN"                                                      \
         -D namespace="$INGRESS_NAMESPACE"                                    \
         -D gateway_name="$INGRESS_GATEWAY_NAME"                              \
         -D gateway_namespace="$INGRESS_NAMESPACE"                            \
         -D gateway_class_name="$GATEWAY_CLASS_NAME"                          \
         -D extauth_enabled="$EXTAUTH_FLAG"                                   \
         -D traffic_policy_name="$TRAFFIC_POLICY_NAME"                        \
         -D service="$GSI_APP_SERVICE_NAME"                                   \
         -D service_namespace="$GSI_APP_SERVICE_NAMESPACE"                    \
         -D service_port="$GSI_APP_SERVICE_PORT"                              \
         -D multicluster="$MC_FLAG"                                           \
         "$TEMPLATES"/httproute.manifest.yaml.j2                              \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}

function create_httproute {
  local _service_name _service_port _namespace
  while getopts "m:n:p:s:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      m)
        _service_name=$OPTARG ;;
      s)
        _service_namespace=$OPTARG ;;
      n)
        _namespace=$OPTARG ;;
      p)
        _service_port=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/httproute.${_service_name}.${_namespace}.${GSI_CLUSTER}.yaml"

  exec_gateway_api_crds

  jinja2 -D tldn="$TLDN"                                                      \
         -D namespace="$_namespace"                                           \
         -D gateway_name="$INGRESS_GATEWAY_NAME"                              \
         -D gateway_namespace="$INGRESS_NAMESPACE"                            \
         -D gateway_class_name="$GATEWAY_CLASS_NAME"                          \
         -D extauth_enabled="$EXTAUTH_FLAG"                                   \
         -D traffic_policy_name="$TRAFFIC_POLICY_NAME"                        \
         -D service="$_service_name"                                          \
         -D service_namespace="$_service_namespace"                           \
         -D service_port="$_service_port"                                     \
         -D multicluster="$MC_FLAG"                                           \
         "$TEMPLATES"/httproute.manifest.yaml.j2                              \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  # TODO if _service_namespace != _namespace
  # create_reference_grant
  if [[ $_service_namespace != "$_namespace" ]]; then
    create_reference_grant -m "$_service_name" -s "$_service_namespace" -n "$_namespace"
  fi
}

function exec_backend {
  local _manifest="$MANIFESTS/backend.${GSI_CLUSTER}.yaml"

  jinja2 -D tldn="$TLDN"                                                      \
         -D service_name="$GSI_APP_SERVICE_NAME"                              \
         -D service_namespace="$GSI_APP_SERVICE_NAMESPACE"                    \
         -D service_port="$GSI_APP_SERVICE_PORT"                              \
         "$TEMPLATES"/backend.manifest.yaml.j2                                \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}

function exec_reference_grant {
  local _manifest="$MANIFESTS/reference_grant.${GSI_CLUSTER}.yaml"

  jinja2 -D gateway_namespace="$INGRESS_NAMESPACE"                            \
         -D service="$GSI_APP_SERVICE_NAME"                                   \
         -D service_namespace="$GSI_APP_SERVICE_NAMESPACE"                    \
         -D multicluster="$MC_FLAG"                                           \
         "$TEMPLATES"/reference_grant.manifest.yaml.j2                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}

function create_reference_grant {

  while getopts "m:n:s:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      m)
        _service_name=$OPTARG ;;
      n)
        _namespace=$OPTARG ;;
      s)
        _service_namespace=$OPTARG ;;
    esac
  done
  local _manifest="$MANIFESTS/reference_grant.${_service_name}.${_service_namespace}.${GSI_CLUSTER}.yaml"

  jinja2 -D gateway_namespace="$_namespace"                                   \
         -D service="$_service_name"                                          \
         -D service_namespace="$_service_namespace"                           \
         -D multicluster="$MC_FLAG"                                           \
         "$TEMPLATES"/reference_grant.manifest.yaml.j2                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}

function exec_gloo_gateway_v2_keycloak_secret {
  create_keycloak_secret "$GLOO_GATEWAY_V2_NAMESPACE"
}

function exec_kgateway_keycloak_secret {
  create_keycloak_secret "$KGATEWAY_SYSTEM_NAMESPACE"
}

function exec_extauth_keycloak_ggv2_auth_config {
  local _gateway_address
  local _manifest="$MANIFESTS/auth_config.oauth.${GSI_CLUSTER}.yaml"

##  _gateway_address=$(
##    kubectl get svc "$INGRESS_GATEWAY_NAME"                                   \
##    --context "$GSI_CONTEXT"                                                  \
##    --namespace "$INGRESS_NAMESPACE"                                          \
##    -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  jinja2 -D namespace="$GSI_APP_SERVICE_NAMESPACE"                            \
         -D gateway_address="${GSI_APP_SERVICE_NAME}.${TLDN}"                 \
         -D http_port="$HTTP_INGRESS_PORT"                                    \
         -D client_id="$KEYCLOAK_CLIENT"                                      \
         -D system_namespace="$GLOO_GATEWAY_V2_NAMESPACE"                     \
         -D keycloak_url="$KEYCLOAK_URL"                                      \
         -D gateway_class_name="$GATEWAY_CLASS_NAME"                          \
         -D gateway_namespace="$INGRESS_NAMESPACE"                            \
         -D traffic_policy_name="$TRAFFIC_POLICY_NAME"                        \
         -D httproute_name="${GSI_APP_SERVICE_NAME}-route"                    \
         "$TEMPLATES"/auth_config.oauth.manifest.yaml.j2                      \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}
