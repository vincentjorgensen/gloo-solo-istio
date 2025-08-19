#!/usr/bin/env bash
function app_init_curl {
  if $CURL_ENABLED; then
    exec_curl
  fi
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
