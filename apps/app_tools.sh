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

function app_init_curl {
  if $CURL_ENABLED; then
    exec_curl
  fi
}

function exec_utils {
  local _manifest="$MANIFESTS/tools.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/utils.manifest.yaml.j2

  _label_ns_for_istio "$UTILS_NAMESPACE"

  jinja2                                                                      \
         "$_template"                                                         \
         "$J2_GLOBALS"                                                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  _wait_for_pods "$UTILS_NAMESPACE" utils
}

function exec_netshoot {
  local _manifest="$MANIFESTS/netshoot.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/netshoot.manifest.yaml.j2

  _label_ns_for_istio "$NETSHOOT_NAMESPACE"

  jinja2                                                                      \
         "$_template"                                                         \
         "$J2_GLOBALS"                                                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  _wait_for_pods "$NETSHOOT_NAMESPACE" netshoot
}


function exec_curl {
  local _manifest="$MANIFESTS/curl.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/curl.manifest.yaml.j2

  _label_ns_for_istio "$CURL_NAMESPACE"

  jinja2                                                                      \
         "$_template"                                                         \
         "$J2_GLOBALS"                                                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"

  _wait_for_pods "$CURL_NAMESPACE" curl
}
