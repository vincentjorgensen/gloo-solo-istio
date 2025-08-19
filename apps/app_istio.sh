#!/usr/bin/env bash
function app_init_istio {
  if $SIDECAR_ENABLED || $AMBIENT_ENABLED; then
    if $AWS_ENABLED && $CERT_MANAGER_ENABLED; then
      create_aws_intermediate_pca Istio
      create_aws_pca_issuer_role Istio
      exec_aws_pca_serviceaccount
      exec_aws_pca_privateca_issuer
      create_aws_pca_issuer -c istio -n istio-system -a "$SUBORDNIATE_CAARN"
      ### create_aws_pca_cluster_issuer -c istio -n default -a "$ROOT_CAARN" # -a "$SUBORDNIATE_CAARN"
      exec_istio_awspca_secrets
    else
      if $MULTICLUSTER_ENABLED; then
        if ! $SPIRE_ENABLED; then
          exec_istio_secrets
        fi
      fi
    fi
    exec_istio
    exec_telemetry_defaults

    if $MULTICLUSTER_ENABLED; then
      gsi_cluster_swap
      if $AWS_ENABLED && $CERT_MANAGER_ENABLED; then
        create_aws_pca_issuer_role Istio
        exec_aws_pca_serviceaccount
        exec_aws_pca_privateca_issuer
        create_aws_pca_cluster_issuer -c istio -n istio-system -a "$SUBORDNIATE_CAARN"
        ### create_aws_pca_cluster_issuer -c istio -n default -a "$ROOT_CAARN" # -a "$SUBORDNIATE_CAARN"
        exec_istio_awspca_secrets
      else
        if ! $SPIRE_ENABLED; then
          exec_istio_secrets
        fi
      fi
      exec_istio
      exec_telemetry_defaults
      gsi_cluster_swap
    fi
  fi
}

function exec_istio_secrets {
  if is_create_mode; then
    $DRY_RUN kubectl "$GSI_MODE" secret generic "$ISTIO_SECRET"               \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --from-file="$CERTS"/"$GSI_CLUSTER"/ca-cert.pem                           \
    --from-file="$CERTS"/"$GSI_CLUSTER"/ca-key.pem                            \
    --from-file="$CERTS"/"$GSI_CLUSTER"/root-cert.pem                         \
    --from-file="$CERTS"/"$GSI_CLUSTER"/cert-chain.pem
  else
    $DRY_RUN kubectl "$GSI_MODE" secret cacerts                               \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_istio_awspca_secrets {
  local _manifest="$MANIFESTS"/certificate.cert-manager."$GSI_CLUSTER".yaml

  jinja2 -D component="istio"                                                 \
         -D revision="$REVISION"                                              \
         -D issuer_name="$AWSPCA_ISSUER"                                      \
         -D issuer_kind="$AWSPCA_ISSUER_KIND"                                 \
         -D namespace="$ISTIO_SYSTEM_NAMESPACE"                               \
         -D secret_name="$ISTIO_SECRET"                                       \
         -D trust_domain="$TRUST_DOMAIN"                                      \
         "$TEMPLATES"/certificate.cert-manager.manifest.yaml.j2               \
  > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}

function exec_istio_base {
  local _cluster=$GSI_CLUSTER
  local _context=$GSI_CONTEXT

  while getopts "c:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _cluster=$OPTARG ;;
      x)
        _context=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/helm.istio-base.${_cluster}.yaml"

  if is_create_mode; then
    jinja2 -D revision="$REVISION"                                            \
           "$TEMPLATES"/helm.istio-base.yaml.j2                               \
      > "$_manifest"

    # shellcheck disable=SC2086
    $DRY_RUN helm upgrade --install istio-base "$HELM_REPO"/base              \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$_context"                                                \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --create-namespace                                                        \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall istio-base                                        \
    --kube-context="$_context"                                                \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_istio_istiod {
  local _manifest="$MANIFESTS/helm.istiod.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/helm.istiod.yaml.j2

  if is_create_mode; then
    jinja2                                                                    \
         -D cluster="$GSI_CLUSTER"                                            \
         -D trust_domain="$TRUST_DOMAIN"                                      \
         -D remote_trust_domain="$REMOTE_TRUST_DOMAIN"                        \
         -D network="$GSI_NETWORK"                                            \
         "$_template"                                                         \
         "$J2_GLOBALS"                                                        \
    > "$_manifest"

    $DRY_RUN helm upgrade --install istiod "$HELM_REPO"/istiod                \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall istiod                                            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_istio_cni {
  local _manifest="$MANIFESTS/helm.istio-cni.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/helm.istio-cni.yaml.j2

  if is_create_mode; then
    jinja2                                                                    \
         "$_template"                                                         \
         "$J2_GLOBALS"                                                        \
    > "$_manifest"

    $DRY_RUN helm upgrade --install istio-cni "$HELM_REPO"/cni                \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall istio-cni                                         \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_istio_ztunnel {
  local _manifest="$MANIFESTS/helm.ztunnel.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/helm.ztunnel.yaml.j2

  if is_create_mode; then
    jinja2                                                                    \
           -D cluster="$GSI_CLUSTER"                                          \
           -D network="$GSI_NETWORK"                                          \
         "$_template"                                                         \
         "$J2_GLOBALS"                                                        \
    > "$_manifest"

    $DRY_RUN helm upgrade --install ztunnel "$HELM_REPO"/ztunnel              \
    --version "${ISTIO_VER}${ISTIO_FLAVOR}"                                   \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall ztunnel                                           \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"
  fi
}

function exec_telemetry_defaults {
  cp "$TEMPLATES"/telemetry.istio-system.manifest.yaml                        \
     "$MANIFESTS"/telemetry.istio-system."$GSI_CLUSTER".yaml

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$MANIFESTS"/telemetry.istio-system."$GSI_CLUSTER".yaml
}

function exec_istio {
  local _k_label="=$GSI_NETWORK"

  if [[ $GSI_MODE == delete ]]; then
    _k_label="-"
  fi

  if $MULTICLUSTER_ENABLED; then
    $DRY_RUN kubectl label namespace "$ISTIO_SYSTEM_NAMESPACE" "topology.istio.io/network${_k_label}"  \
    --context "$GSI_CONTEXT" --overwrite
  fi

  exec_istio_base
  exec_istio_istiod
  "$AMBIENT_ENABLED" && exec_istio_cni
  "$AMBIENT_ENABLED" && exec_istio_ztunnel

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$ISTIO_SYSTEM_NAMESPACE"                                     \
    --for=condition=Ready pods --all
  fi
}
