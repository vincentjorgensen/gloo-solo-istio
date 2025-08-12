#!/usr/bin/env bash
function app_init_namespaces {
  exec_namespaces

  if $MULTICLUSTER_ENABLED; then
    gsi_cluster_swap
    exec_namespaces
    gsi_cluster_swap
  fi

  if $GME_ENABLED; then
    create_namespace "$GSI_MGMT_CONTEXT" "$GSI_NAMESPACE"
  fi
}

function exec_namespaces {
  for enabled_var in $(env|grep _ENABLED); do
    enabled=$(echo "$enabled_var" | awk -F= '{print $1}')
    if eval '$'"${enabled}"; then
      # shellcheck disable=SC2116
      if [[ -n "$(eval echo '$'"$(echo "${enabled%%_ENABLED}_NAMESPACE")")" ]]; then
        echo '#' "${enabled%%_ENABLED} is enabled, creating namespace $(eval echo '$'"${enabled%%_ENABLED}_NAMESPACE")"
        create_namespace "$GSI_CONTEXT" "$(eval echo '$'"$(echo "${enabled%%_ENABLED}_NAMESPACE")")"
      fi
    fi
  done
}

function create_namespace {
  local _context _namespace
  _context=$1
  _namespace=$2

  $DRY_RUN kubectl "$GSI_MODE" namespace "$_namespace"                        \
  --context "$_context"
}
