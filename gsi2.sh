#!/usr/bin/env bash
source "$(dirname "$0")"/globals2.sh
for app in "$(dirname "$0")"/apps/*; do
  # shellcheck source=/dev/null
  source "$app"
done

GSI_DECK=(
  gsi_init

  app_init_namespaces

  app_init_aws

  app_init_external_dns

  app_init_spire
  app_init_cert_manager
  app_init_keycloak
  app_init_gme
  app_init_istio

  app_init_istio_gateway
  app_init_gateway_api
  app_init_gme_workspaces

  app_init_helloworld
  app_init_curl
  app_init_utils
  app_init_netshoot
  app_init_httpbin

  ###app_init_ingress_istio
  app_init_eastwest_gateway_api
  app_init_ingress_gateway_api

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
