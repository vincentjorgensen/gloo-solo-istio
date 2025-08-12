#!/usr/bin/env bash
function app_init_helloworld {
  if $HELLOWORLD_ENABLED; then
    export HW_SVC_VER=$((HW_SVC_VER+1))
    exec_helloworld

    if $MULTICLUSTER_ENABLED; then
      HW_SVC_VER=$((HW_SVC_VER+1))
      gsi_cluster_swap
      exec_helloworld
      gsi_cluster_swap
    fi

    if $EXTAUTH_ENABLED; then
      create_keycloak_extauth_auth_config -m "$HELLOWORLD_SERVICE_NAME"       \
                                          -s "$HELLOWORLD_NAMESPACE"          \
                                          -h "$HELLOWORLD_NAMESPACE"          \
                                          -n "$HELLOWORLD_NAMESPACE"          \
                                          -p "$HELLOWORLD_SERVICE_PORT"

    fi

    if $GATEWAY_API_ENABLED; then
###      create_httproute -m "$HELLOWORLD_SERVICE_NAME"                          \
###                       -n "$INGRESS_NAMESPACE"                                \
###                       -s "$HELLOWORLD_NAMESPACE"                             \
###                       -p "$HELLOWORLD_SERVICE_PORT"
      create_httproute -m "$HELLOWORLD_SERVICE_NAME"                          \
                       -n "$HELLOWORLD_NAMESPACE"                             \
                       -s "$HELLOWORLD_NAMESPACE"                             \
                       -p "$HELLOWORLD_SERVICE_PORT"
    fi

    if $GME_ENABLED; then
      create_gloo_route_table -w "$GME_APPLICATIONS_WORKSPACE" -s "$HELLOWORLD_SERVICE_NAME"
      create_gloo_virtual_destination -w "$GME_APPLICATIONS_WORKSPACE" -s "$HELLOWORLD_SERVICE_NAME" -p "$HELLOWORLD_SERVICE_PORT"
    fi
  fi
}

function exec_helloworld {
  local _manifest="$MANIFESTS/helloworld.${GSI_CLUSTER}.yaml"
  local _region _zones _ztemp _service_version


###  $DRY_RUN kubectl label namespace "$HELLOWORLD_NAMESPACE" "name=$HELLOWORLD_NAMESPACE" \
###  --context "$GSI_CONTEXT" --overwrite

  if $AMBIENT_ENABLED; then
    local _k_label="=ambient"

    if ! is_create_mode; then
      _k_label="-"
    fi
    $DRY_RUN kubectl label namespace "$HELLOWORLD_NAMESPACE" "istio.io/dataplane-mode${_k_label}"  \
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
    $DRY_RUN kubectl label namespace "$HELLOWORLD_NAMESPACE" "${_k_key}${_k_label}"  \
    --context "$GSI_CONTEXT" --overwrite
  fi

  # Traffic Distribution: PreferNetwork, PreferClose, PreferRegion, Any
  _ztemp=$(mktemp)
  _region=$(get_k8s_region "$GSI_CONTEXT")
  _zones=$(get_k8s_zones "$GSI_CONTEXT")

  echo "zones:" > "$_ztemp"

  while read -r zone; do
    echo "- $zone" >> "$_ztemp"
  done <<< "$_zones"

  cp "$_ztemp" "$_ztemp".yaml

###  [[ $_region =~ west ]] && _service_version=v1
###  [[ $_region =~ east ]] && _service_version=v2
  _service_version="v${HW_SVC_VER}"
  [[ -n $GSI_SERVICE_VERSION ]] && _service_version="$GSI_SERVICE_VERSION"

  jinja2 -D region="$_region"                                                 \
         -D service_version="${_service_version:-none}"                       \
         -D ambient_enabled="$AMBIENT_FLAG"                                   \
         -D sidecar_enabled="$SIDECAR_FLAG"                                   \
         -D traffic_distribution="${TRAFFIC_DISTRIBUTION:-Any}"               \
         -D size="${GSI_APP_SIZE:-1}"                                         \
         -D namespace="$HELLOWORLD_NAMESPACE"                                 \
         -D service_port="$HELLOWORLD_SERVICE_PORT"                           \
         -D service_name="$HELLOWORLD_SERVICE_NAME"                           \
         "$TEMPLATES"/helloworld.manifest.yaml.j2                             \
         "$_ztemp".yaml                                                       \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$HELLOWORLD_NAMESPACE"                                       \
    --for=condition=Ready pods -l app=helloworld
  fi
}

