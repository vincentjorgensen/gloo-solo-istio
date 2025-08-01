#!/usr/bin/env bash

function app_init_tools {
  if $TOOLS_ENABLED; then
    exec_tools
  fi
}

function exec_tools {
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

  jinja2 -D namespace="$TOOLS_NAMESPACE"                                      \
         "$TEMPLATES"/tools.manifest.yaml.j2                                  \
  > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$TOOLS_NAMESPACE"                                            \
    --for=condition=Ready pods -l app=tools
  fi

  alias ktools="kubectl --context \$GSI_CONTEXT --namespace \$TOOLS_NAMESPACE exec -it deployment/tools -- bash"
}
