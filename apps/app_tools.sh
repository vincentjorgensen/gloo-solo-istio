#!/usr/bin/env bash

function app_init_utils {
  if $UTILS_ENABLED; then
    exec_utils
  fi
}

function app_init_netshoot {
  if $NETSHOOT_ENABLED; then
    exec_netshoot
  fi
}

function exec_utils {
  local _manifest="$MANIFESTS/tools.${GSI_CLUSTER}.yaml"

  if $AMBIENT_ENABLED; then
    local _k_label="=ambient"

    if ! is_create_mode; then
      _k_label="-"
    fi
    $DRY_RUN kubectl label namespace "$TOOLS_NAMESPACE" "istio.io/dataplane-mode${_k_label}"  \
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
    $DRY_RUN kubectl label namespace "$TOOLS_NAMESPACE" "${_k_key}${_k_label}"  \
    --context "$GSI_CONTEXT" --overwrite
  fi

  jinja2 -D tools_namespace="$TOOLS_NAMESPACE"                                \
         "$TEMPLATES"/utils.manifest.yaml.j2                                  \
  > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  wait_for_pods "$TOOLS_NAMESPACE" utils
}

function exec_netshoot {
  local _manifest="$MANIFESTS/netshoot.${GSI_CLUSTER}.yaml"

  jinja2 -D tools_namespace="$TOOLS_NAMESPACE"                                \
         "$TEMPLATES"/netshoot.manifest.yaml.j2                               \
  > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  wait_for_pods "$TOOLS_NAMESPACE" netshoot
}
