function app_init_gloo_edge {
  if $GLOO_EDGE_ENABLED; then
    exec_gloo_edge

    if $GME_ENABLED; then
      exec_gloo_virtual_gateway
    fi
  fi
}

function exec_gloo_edge {
  local _manifest="$MANIFESTS/helm.gloo-edge.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/helm.gloo-gateway.yaml.j2

  jinja2                                                                       \
         "$_template"                                                          \
         "$J2_GLOBALS"                                                         \
  > "$_manifest"

  if is_create_mode; then
    $DRY_RUN helm upgrade -i gloo-edge glooe/gloo-ee                           \
    --version="$GLOO_EDGE_VER"                                                 \
    --kube-context="$GSI_CONTEXT"                                              \
    --namespace="$GLOO_EDGE_NAMESPACE"                                         \
    --values "$_manifest"                                                      \
    --wait
  else
    $DRY_RUN helm uninstall gloo-edge                                          \
    --kube-context="$GSI_CONTEXT"                                              \
    --namespace="$GLOO_EDGE_NAMESPACE"
  fi
}

###function exec_gloo_edge_gateway {
###  local _manifest="$MANIFESTS/gloo_edge.ingress_gateway.${GSI_CLUSTER}.yaml"
###  local _template="$TEMPLATES/gloo_edge.ingress_gateway.manifest.yaml.j2"
###
###  jinja2                                                                       \
###         "$_template"                                                          \
###         "$J2_GLOBALS"                                                         \
###  > "$_manifest"
###
###  $DRY_RUN kubectl "$GSI_MODE"                                                 \
###  --context "$GSI_CONTEXT"                                                     \
###  -f "$_manifest"
###}

function create_gloo_edge_virtual_service {
  local _service _service_namespace _service_port
  while getopts "s:n:p:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      s)
        _service=$OPTARG ;;
      n)
        _service_namespace=$OPTARG ;;
      p)
        _service_port=$OPTARG ;;
    esac
  done
  
  local _manifest="$MANIFESTS/gloo_edge.virtual_service.${_service}.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/gloo_edge/virtual_service.manifest.yaml.j2

  jinja2 -D service="$_service"                                                \
         -D service_namespace="$_service_namespace"                            \
         -D service_port="$_service_port"                                      \
         "$_template"                                                          \
         "$J2_GLOBALS"                                                         \
  > "$_manifest"

  _apply_manifest "$_manifest"
}
