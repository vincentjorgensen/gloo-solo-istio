function app_init_gloo_gateway {
  if $GLOO_GATEWAY_ENABLED; then
    exec_gateway_api_crds
    exec_gloo_gateway
  fi
}

function exec_gloo_gateway {
  local _manifest="$MANIFESTS/helm.gloo-gateway.${GSI_CLUSTER}.yaml"

    jinja2 -D gloo_gateway_license_key="$GLOO_GATEWAY_LICENSE_KEY"            \
           "$TEMPLATES"/helm.gloo-gateway.yaml.j2                             \
      > "$_manifest"

  if is_create_mode; then
    $DRY_RUN helm upgrade -i gloo-gateway glooe/gloo-ee                       \
    --version="$GLOO_GATEWAY_VER"                                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_GATEWAY_NAMESPACE"                                     \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall gloo-gateway                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_GATEWAY_NAMESPACE"
  fi
}

function exec_gloo_gateway_gateway {
  local _manifest="$MANIFESTS/gloo_gateway.gateway.${GSI_CLUSTER}.yaml"

  jinja2 -D ingress_gateway_name="$INGRESS_GATEWAY_NAME"                      \
         -D ingress_namespace="$INGRESS_NAMESPACE"                            \
         -D gateway_class_name="$GATEWAY_CLASS_NAME"                          \
         -D size="${INGRESS_SIZE:-1}"                                         \
         -D tldn="$TLDN"                                                      \
        "$TEMPLATES"/gloo_gateway.gateway.manifest.yaml.j2                    \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}
