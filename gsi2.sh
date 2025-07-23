#!/usr/bin/env bash
source "$(dirname "$0")"/globals2.sh
for app in "$(dirname "$0")"/apps/*; do
  # shellcheck source=/dev/null
  source "$app"
done

GSI_DECK=(
  set_defaults
  gsi_init

  app_init_namespaces
  app_init_spire
  app_init_cert_manager
  app_init_istio

  app_init_helloworld
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
  export GSI_MODE=delete
  # shellcheck disable=SC2296
  for exe in "${(Oa)GSI_DECK[@]}"; do
    echo '#'"$exe"
    eval "$exe"
  done
}

function dry_run_gsi {
  export DRY_RUN="echo"
  for exe in "${GSI_DECK[@]}"; do
    echo '#'"$exe"
    eval "$exe"
  done
  export DRY_RUN=""
}
