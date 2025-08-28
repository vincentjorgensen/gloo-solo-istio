#!/usr/bin/env bash
function app_init_helloworld {
  if $HELLOWORLD_ENABLED; then
    export HW_SVC_VER=$((HW_SVC_VER+1))
    exec_helloworld

    if $MULTICLUSTER_ENABLED; then
      HW_SVC_VER=$((HW_SVC_VER+1))
      gsi_cluster_swap
      _jinja2_values # swaps region/zone to remote
      exec_helloworld
      gsi_cluster_swap
      _jinja2_values # swaps region/zone to local
    fi

    if $EXTAUTH_ENABLED; then
      create_keycloak_extauth_auth_config -m "$HELLOWORLD_SERVICE_NAME"        \
                                          -s "$HELLOWORLD_NAMESPACE"           \
                                          -h "$HELLOWORLD_NAMESPACE"           \
                                          -n "$HELLOWORLD_NAMESPACE"           \
                                          -p "$HELLOWORLD_SERVICE_PORT"

    fi

    if $GATEWAY_API_ENABLED; then
      create_httproute -m "$HELLOWORLD_SERVICE_NAME"                           \
                       -n "$HELLOWORLD_NAMESPACE"                              \
                       -s "$HELLOWORLD_NAMESPACE"                              \
                       -p "$HELLOWORLD_SERVICE_PORT"
    fi

    if $GLOO_EDGE_ENABLED; then
      create_gloo_route_table                                                  \
        -w "$GME_APPLICATIONS_WORKSPACE"                                       \
        -s "$HELLOWORLD_SERVICE_NAME"
      create_gloo_virtual_destination                                          \
        -w "$GME_APPLICATIONS_WORKSPACE"                                       \
        -s "$HELLOWORLD_SERVICE_NAME"                                          \
        -p "$HELLOWORLD_SERVICE_PORT"
    fi
  fi
}

function exec_helloworld {
  local _manifest="$MANIFESTS/helloworld.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/helloworld.manifest.yaml.j2

  _label_ns_for_istio "$HELLOWORLD_NAMESPACE"

  _service_version="v${HW_SVC_VER}"
  [[ -n $GSI_SERVICE_VERSION ]] && _service_version="$GSI_SERVICE_VERSION"

  jinja2                                                                       \
         -D helloworld_service_version="${_service_version:-none}"             \
         "$_template"                                                          \
         "$J2_GLOBALS"                                                         \
    > "$_manifest"

  _apply_manifest "$_manifest"
  _wait_for_pods "$GSI_CONTEXT" "$HELLOWORLD_NAMESPACE" helloworld
}
