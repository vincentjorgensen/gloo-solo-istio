#!/usr/bin/env bash
source "$(dirname "$0")"/globals.sh
source "$(dirname "$0")"/execs.sh
source "$(dirname "$0")"/decks.sh
source "$(dirname "$0")"/plays.sh

function play_gsi {
  export GSI_MODE=create
  for exe in "${GSI_DECK[@]}"; do
    eval "$exe"
  done
}

function rew_gsi {
  export GSI_MODE=delete
  # shellcheck disable=SC2296
  for exe in "${(Oa)GSI_DECK[@]}"; do
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