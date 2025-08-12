#!/usr/bin/env bash

function app_init_httpbin {
  if $HTTPBIN_ENABLED; then
    if $MULTICLUSTER_ENABLED; then
      gsi_cluster_swap
      exec_httpbin
      gsi_cluster_swap
    else
      exec_httpbin
    fi

    if $GATEWAY_API_ENABLED; then
      create_httproute -m "$HTTPBIN_SERVICE_NAME"                             \
                       -n "$HTTPBIN_NAMESPACE"                                \
                       -s "$HTTPBIN_NAMESPACE"                                \
                       -p "$HTTPBIN_SERVICE_PORT"
    fi

    if $GME_ENABLED; then
      create_gloo_route_table -w "$GME_APPLICATIONS_WORKSPACE" -s "$HTTPBIN_SERVICE_NAME"
      create_gloo_virtual_destination -w "$GME_APPLICATIONS_WORKSPACE" -s "$HTTPBIN_SERVICE_NAME" -p "$HTTPBIN_SERVICE_PORT"
    fi
 fi
}

function exec_httpbin {
  local _manifest="$MANIFESTS/httpbin.${GSI_CLUSTER}.yaml"

  if $AMBIENT_ENABLED; then
    local _k_label="=ambient"

    if ! is_create_mode; then
      _k_label="-"
    fi
    $DRY_RUN kubectl label namespace "$HTTPBIN_NAMESPACE" "istio.io/dataplane-mode${_k_label}"  \
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
    $DRY_RUN kubectl label namespace "$HTTPBIN_NAMESPACE" "${_k_key}${_k_label}" \
    --context "$GSI_CONTEXT" --overwrite
  fi

  jinja2 -D httpbin_namespace="$HTTPBIN_NAMESPACE"                            \
         -D httpbin_service_name="$HTTPBIN_SERVICE_NAME"                      \
         -D httpbin_service_port="$HTTPBIN_SERVICE_PORT"                      \
         -D ambient_enabled="$AMBIENT_FLAG"                                   \
         -D traffic_distribution="${TRAFFIC_DISTRIBUTION:-Any}"               \
         "$TEMPLATES"/httpbin.manifest.yaml.j2                                \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$HTTPBIN_NAMESPACE"                                          \
    --for=condition=Ready pods -l app=httpbin
  fi
}
