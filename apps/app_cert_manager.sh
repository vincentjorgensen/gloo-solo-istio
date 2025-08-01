#!/usr/bin/env bash
function app_init_cert_manager {
  if $CERT_MANAGER_ENABLED; then
    if $DOCKER_DESKTOP_ENABLED; then
      exec_cert_manager_secrets
    fi
    exec_cert_manager
    if $MULTICLUSTER_ENABLED; then
      gsi_cluster_swap
      exec_cert_manager
      gsi_cluster_swap
    fi
    exec_cert_manager_cluster_issuer
  fi
}

function exec_cert_manager_secrets {
  if is_create_mode; then
    $DRY_RUN kubectl "$GSI_MODE" secret generic "$CERT_MANAGER_SECRET"        \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$CERT_MANAGER_NAMESPACE"                                     \
    --from-file=tls.crt="$CERT_MANAGER_CERTS"/root-cert.pem                   \
    --from-file=tls.key="$CERT_MANAGER_CERTS"/root-key.pem
  else
    $DRY_RUN kubectl "$GSI_MODE" secret "$CERT_MANAGER_SECRET"                \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$CERT_MANAGER_NAMESPACE"
  fi
}

function exec_cert_manager {
  if is_create_mode; then

    # Requires Gateway API CRDs
    exec_gateway_api_crds 
 
    $DRY_RUN helm upgrade --install cert-manager jetstack/cert-manager        \
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
  
  jinja2 -D namespace="$CERT_MANAGER_NAMESPACE"                               \
         "$TEMPLATES"/cluster_issuer.cert-manager.manifest.yaml.j2            \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}

function create_cert_manager_issuer {
    local _name _namespace _org _secret_name

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

  jinja2 -D name="$_name"                                                     \
         -D namespace="$_namespace"                                           \
         -D serial_no="$(date +%Y%m%d)"                                       \
         -D org="$_org"                                                       \
         -D ou="$_ou"                                                         \
         -D country="$_country"                                               \
         -D state="$_state"                                                   \
         -D locale="$_locale"                                                 \
         -D secret_name="$_secret_name"                                       \
         -D tldn="$TLDN"                                                      \
         "$TEMPLATES"/issuer.cert-manager.manifest.yaml.j2                    \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}
