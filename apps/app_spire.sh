#!/usr/bin/env bash
function app_init_spire {
  if $SPIRE_ENABLED; then
    exec_spire_secrets
    exec_spire_crds
    exec_spire_server
  fi
}

function exec_spire_secrets {
  if is_create_mode; then
###    kubectl "$GSI_MODE" secret generic "$SPIRE_SECRET"                        \
###    --context "$GSI_CONTEXT"                                                  \
###    --namespace "$SPIRE_NAMESPACE"                                            \
###    --from-file=tls.crt="$SPIRE_CERTS"/"${GSI_CLUSTER}"/ca-cert.pem           \
###    --from-file=tls.key="$SPIRE_CERTS"/"${GSI_CLUSTER}"/ca-key.pem            \
###    --from-file=bundle.crt="$SPIRE_CERTS"/"${GSI_CLUSTER}"/cert-chain.pem
    $DRY_RUN kubectl "$GSI_MODE" secret generic "$SPIRE_SECRET"               \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$SPIRE_NAMESPACE"                                            \
    --from-file=tls.crt="$SPIRE_CERTS"/root-cert.pem                          \
    --from-file=tls.key="$SPIRE_CERTS"/root-key.pem
  else
    $DRY_RUN kubectl "$GSI_MODE" secret "$SPIRE_SECRET"                       \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$SPIRE_NAMESPACE"
  fi
}

function exec_spire_crds {
  if is_create_mode; then
    # shellcheck disable=SC2086
    $DRY_RUN helm upgrade --install spire-crds spire/spire-crds                        \
    --version "$SPIRE_CRDS_VER"                                               \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_NAMESPACE"                                            \
    --wait
  else
    $DRY_RUN helm uninstall spire-crds                                                 \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_NAMESPACE"
  fi
}

function exec_spire_server {
  local _manifest="$MANIFESTS/helm.spire.${GSI_CLUSTER}.yaml"

  if is_create_mode; then
    jinja2 -D trust_domain="$TRUST_DOMAIN"                                    \
           -D spire_secret="$SPIRE_SECRET"                                    \
           "$TEMPLATES"/helm.spire.yaml.j2                                    \
      > "$_manifest"

    # shellcheck disable=SC2086
    $DRY_RUN helm upgrade --install spire spire/spire                         \
    --version "$SPIRE_SERVER_VER"                                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_NAMESPACE"                                            \
    --values "$_manifest"                                                     \
    --wait

    $DRY_RUN kubectl wait                                                     \
    --namespace "$SPIRE_NAMESPACE"                                            \
    --for=condition=Ready pods --all
  else
    $DRY_RUN helm uninstall spire                                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_NAMESPACE"
  fi

  cp "$TEMPLATES"/spire.cluster-id.manifest.yaml                              \
     "$MANIFESTS"/spire.cluster-id."$GSI_CLUSTER".yaml

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$MANIFESTS"/spire.cluster-id."$GSI_CLUSTER".yaml
}
