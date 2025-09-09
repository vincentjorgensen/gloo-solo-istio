#!/usr/bin/env bash
source "$(dirname "$0")"/globals.sh
for app in "$(dirname "$0")"/apps/*; do
  # shellcheck source=/dev/null
  source "$app"
done

GSI_DECK=(
  gsi_init

  app_init_namespaces

  # Cloud infrastructure
  app_init_aws

  # Infrastructure apps
  app_init_external_dns
  app_init_spire
  app_init_cert_manager
  app_init_keycloak
  app_init_gme
  app_init_istio

  # Infrastructure
  app_init_istio_gateway
  app_init_gateway_api
  app_init_gme_workspaces

  # Test applications
  app_init_helloworld
  app_init_curl
  app_init_utils
  app_init_netshoot
  app_init_httpbin

  # Gateway Choices
  ###app_init_ingress_istio
  app_init_gloo_edge
  app_init_gloo_gateway_v1
  app_init_eastwest_gateway_api
  app_init_ingress_gateway_api

  # App Routing
  exec_helloworld_routing
  exec_httpbin_routing
)

function play_gsi {
  infra=$1

  # shellcheck source=/dev/null
  source "$(dirname "$0")/infras/infra_${infra}.sh"
  export GSI_MODE=create
  for exe in "${GSI_DECK[@]}"; do
    echo '#'"$exe"
    eval "$exe"
  done
}

function rew_gsi {
  infra=$1

  # shellcheck source=/dev/null
  source "$(dirname "$0")/infras/infra_${infra}.sh"
  export GSI_MODE=delete
  # shellcheck disable=SC2296
  for exe in "${(Oa)GSI_DECK[@]}"; do
    echo '#'"$exe"
    eval "$exe"
  done
}

function dry_run_gsi {
  infra=$1

  # shellcheck source=/dev/null
  source "$(dirname "$0")/infras/infra_${infra}.sh"
  export DRY_RUN="echo"
  for exe in "${GSI_DECK[@]}"; do
    echo '#'"$exe"
    eval "$exe"
  done
  export DRY_RUN=""
}

function zip_gsi {
  dry_run_gsi "$1" | tee -a "run_${UTAG}.sh"
  zip "$REPLAYS/${UTAG}.zip" "run_${UTAG}.sh" "$MANIFESTS"/*
  echo '# '"$REPLAYS/${UTAG}.zip"
}

function dry_run_e {
  local _exec="$*"
  DRY_RUN='echo' eval "$*"
}
