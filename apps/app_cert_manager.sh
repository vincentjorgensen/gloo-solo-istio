#!/usr/bin/env bash
function app_init_cert_manager {
  if $CERT_MANAGER_ENABLED; then
    $ITER_MC exec_cert_manager
  fi
}

function exec_cert_manager_secrets {
  if is_create_mode; then
    $DRY_RUN kubectl create secret generic "$CERT_MANAGER_INGRESS_SECRET"      \
    --context "$GSI_CONTEXT"                                                   \
    --namespace "$CERT_MANAGER_NAMESPACE"                                      \
    --from-file=tls.crt="$CERT_MANAGER_CERTS"/root-cert.pem                    \
    --from-file=tls.key="$CERT_MANAGER_CERTS"/root-key.pem
  else
    $DRY_RUN kubectl "$GSI_MODE" secret "$CERT_MANAGER_SECRET"                 \
    --context "$GSI_CONTEXT"                                                   \
    --namespace "$CERT_MANAGER_NAMESPACE"
  fi
}

function exec_cert_manager {
  if is_create_mode; then

    $DRY_RUN helm upgrade --install cert-manager "$CERT_MANAGER_HELM_REPO"    \
    --version "$CERT_MANAGER_VER"                                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$CERT_MANAGER_NAMESPACE"                                     \
    --create-namespace                                                        \
    --set config.apiVersion="controller.config.cert-manager.io/v1alpha1"      \
    --set config.kind="ControllerConfiguration"                               \
    --set config.enableGatewayAPI=true                                        \
    --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}"    \
    --set crds.enabled=true
  else 
    $DRY_RUN helm uninstall cert-manager                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$CERT_MANAGER_NAMESPACE"
  fi

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context="$GSI_CONTEXT"                                                  \
    --namespace "$CERT_MANAGER_NAMESPACE"                                     \
    --for=condition=Ready pods --all
  fi
}

function exec_cert_manager_cluster_issuer {
  local _manifest="$MANIFESTS/cluster_issuer.cert-manager.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/cluster_issuer.cert-manager.manifest.yaml.j2

  _make_manifest "$_template" > "$_manifest"
  _apply_manifest "$_manifest"
}

function create_cert_manager_issuer {
    local _name _namespace _org _secret_name _country _locale _state _ou

    while getopts "c:l:m:n:o:p:s:u:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _country=$OPTARG ;;
      l)
        _locale=$OPTARG ;;
      m)
        _name=$OPTARG ;;
      n)
        _namespace=$OPTARG ;;
      o)
        _org=$OPTARG ;;
      p)
        _state=$OPTARG ;;
      s)
        _secret_name=$OPTARG ;;
      u)
        _ou=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/issuer.cert-manager.${_name}.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/issuer.cert-manager.manifest.yaml.j2
  local _j2="$MANIFESTS"/jinja2_globals."$GSI_CLUSTER".yaml

  jinja2                                                                      \
         -D serial_no="$(date +%Y%m%d)"                                       \
         "$_template"                                                         \
         "$_j2"                                                               \
  > "$_manifest"

  jinja2 -D name="$_name"                                                     \
         -D namespace="$_namespace"                                           \
         -D org="$_org"                                                       \
         -D ou="$_ou"                                                         \
         -D country="$_country"                                               \
         -D state="$_state"                                                   \
         -D locale="$_locale"                                                 \
         -D secret_name="$_secret_name"                                       \
         "$TEMPLATES"/issuer.cert-manager.manifest.yaml.j2                    \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}
