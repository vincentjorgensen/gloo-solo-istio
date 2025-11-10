function app_init_gloo_gateway_v1 {
  if $GLOO_GATEWAY_V1_ENABLED; then
    exec_gateway_api_crds
    exec_gloo_gateway_v1
  fi
}

function exec_gloo_gateway_v1 {
  local _manifest="$MANIFESTS/helm.gloo-gateway-v1.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/helm.gloo-gateway-v1.yaml.j2

  jinja2                                                                       \
          -D gloo_gateway_license_key="$GLOO_GATEWAY_LICENSE_KEY"              \
         "$_template"                                                          \
         "$J2_GLOBALS"                                                         \
  > "$_manifest"

  if is_create_mode; then
    $DRY_RUN helm upgrade -i gloo-gateway glooe/gloo-ee                        \
    --version="$GLOO_GATEWAY_V1_VER"                                           \
    --kube-context="$GSI_CONTEXT"                                              \
    --namespace="$GLOO_GATEWAY_NAMESPACE"                                      \
    --values "$_manifest"                                                      \
    --wait
  else
    $DRY_RUN helm uninstall gloo-gateway                                       \
    --kube-context="$GSI_CONTEXT"                                              \
    --namespace="$GLOO_GATEWAY_NAMESPACE"
  fi
}

function exec_gloo_gateway_v1_gateway {
  local _manifest="$MANIFESTS/gloo-gateway-v1.gateway.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/gloo-gateway-v1.gateway.manifest.yaml.j2

  jinja2                                                                       \
        "$_template"                                                           \
         "$J2_GLOBALS"                                                         \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                 \
  --context "$GSI_CONTEXT"                                                     \
  -f "$_manifest"
}
