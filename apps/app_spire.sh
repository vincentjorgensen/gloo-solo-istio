#!/usr/bin/env bash
function app_init_spire {
  if $SPIRE_ENABLED; then
    exec_spire_secrets
    exec_spire_crds
    exec_spire_server
    
    if $MULTICLUSTER_ENABLED; then
      gsi_cluster_swap

      exec_spire_secrets
      exec_spire_crds
      exec_spire_server

      exec_exchange_bundles

      gsi_cluster_swap

      exec_exchange_bundles
    fi
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
  local _cm_manifest="$MANIFESTS/spire-${GSI_CLUSTER}/configmap.spire-server.yaml"
  local _kustomize_renderer="$MANIFESTS/spire-${GSI_CLUSTER}/kustomize.sh"
  local _kustomization="$MANIFESTS/spire-${GSI_CLUSTER}/kustomization.yaml"
#  local _federation_patch="$MANIFESTS/spire-${GSI_CLUSTER}/spire-federation-patch.yaml"
  local _post_renderer=""

  if is_create_mode; then
    jinja2 -D trust_domain="$TRUST_DOMAIN"                                    \
           -D spire_secret="$SPIRE_SECRET"                                    \
           -D cluster_name="$GSI_CLUSTER"                                     \
           -D tldn="$TLDN"                                                    \
           -D multicluster_enabled="$MC_FLAG"                                 \
           -D cluster_name="$GSI_CLUSTER"                                     \
           -D remote_cluster_name="$GSI_REMOTE_CLUSTER"                       \
           -D tldn="$TLDN"                                                    \
           "$TEMPLATES"/helm.spire.yaml.j2                                    \
      > "$_manifest"

    if $MULTICLUSTER_ENABLED; then
      [[ ! -e $(dirname "$_kustomize_renderer") ]] && mkdir "$(dirname "$_kustomize_renderer")"

      jinja2 -D trust_domain="$TRUST_DOMAIN"                                  \
             -D remote_trust_domain="$REMOTE_TRUST_DOMAIN"                    \
             -D cluster_name="$GSI_CLUSTER"                                   \
             -D remote_cluster_name="$GSI_REMOTE_CLUSTER"                     \
             -D tldn="$TLDN"                                                  \
             -D spire_namespace="$SPIRE_NAMESPACE"                            \
             -D ca_country="US"                                               \
             -D ca_ou="Customer Success"                                      \
             "$TEMPLATES"/configmap.spire-server.manifest.yaml.j2             \
        > "$_cm_manifest"

      jinja2 -D spire_namespace="$SPIRE_NAMESPACE"                            \
             "$TEMPLATES"/spire.kustomization.yaml.j2                         \
        > "$_kustomization"

##      jinja2 -D spire_namespace="$SPIRE_NAMESPACE"                            \
##             "$TEMPLATES"/spire-federation-patch.yaml.j2                      \
##        > "$_federation_patch"

      cp "$TEMPLATES"/kustomize.sh "$_kustomize_renderer"
      _post_renderer="--post-renderer $_kustomize_renderer"
    fi

    # shellcheck disable=SC2086 disable=SC2046
    $DRY_RUN helm upgrade --install spire spire/spire                         \
    --version "$SPIRE_SERVER_VER"                                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_NAMESPACE"                                            \
    --values "$_manifest"                                                     \
    $(eval echo $_post_renderer)                                              \
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

###  $DRY_RUN kubectl "$GSI_MODE"                                                \
###  --context "$GSI_CONTEXT"                                                    \
###  -f "$MANIFESTS"/spire.cluster-id."$GSI_CLUSTER".yaml
###
###  if $MULTICLUSTER_ENABLED && is_create_mode; then
###    $DRY_RUN kubectl get svc spire-server                                     \
###    --context "$GSI_CONTEXT"                                                  \
###    --namespace "$SPIRE_NAMESPACE"                                            \
###    -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}"          \
###    > "$MANIFESTS"/spire-server.address
###
###    $DRY_RUN kubectl get svc spire-server                                     \
###    --context "$GSI_CONTEXT"                                                  \
###    --namespace "$SPIRE_NAMESPACE"                                            \
###    -o jsonpath="{.spec.ports[0].port}"                                       \
###    > "$MANIFESTS"/spire-server.port
###
###    kubectl get configmap spire-bundle                                        \
###    --context "$GSI_CONTEXT"                                                  \
###    --namespace "$SPIRE_NAMESPACE"                                            \
###    -o json                                                                  |\
###    jq -r '.data."bundle.spiffe"' > "$MANIFESTS"/spire-server.bundle 
###  fi
}

function exec_spire_agent {
  local _manifest="$MANIFESTS/helm.spire.${GSI_CLUSTER}.yaml"
  local _spire_bundle="$MANIFESTS/configmap.spire-bundle.${GSI_CLUSTER}.yaml"

    jinja2 -D spire_bundle="$(cat "$MANIFESTS"/spire-server.bundle)"          \
           "$TEMPLATES"/configmap.spire-bundle.yaml.j2                        \
      > "$_spire_bundle"

    jinja2 -D trust_domain="$TRUST_DOMAIN"                                    \
           -D cluster_name="$GSI_CLUSTER"                                     \
           -D tldn="$TLDN"                                                    \
           -D spire_server_address="$(cat "$MANIFESTS"/spire-server.address)" \
           -D spire_server_port="$(cat "$MANIFESTS"/spire-server.port)"       \
           "$TEMPLATES"/helm.spire-agent.yaml.j2                              \
      > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_spire_bundle"

  if is_create_mode; then
    # shellcheck disable=SC2086
    $DRY_RUN helm upgrade --install spire-agent spire/spire                   \
    --version "$SPIRE_SERVER_VER"                                             \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_NAMESPACE"                                            \
    --values "$_manifest"                                                     \
    --wait

    $DRY_RUN kubectl wait                                                     \
    --namespace "$SPIRE_NAMESPACE"                                            \
    --for=condition=Ready pods --all
  else
    $DRY_RUN helm uninstall spire-agent                                       \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$SPIRE_NAMESPACE"
  fi

  cp "$TEMPLATES"/spire.cluster-id.manifest.yaml                              \
     "$MANIFESTS"/spire.cluster-id."$GSI_CLUSTER".yaml

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$MANIFESTS"/spire.cluster-id."$GSI_CLUSTER".yaml
}

function exec_exchange_bundles {
  local _cmd; _cmd=$(mktemp)
  local _remote_trust_bundle

    cat <<EOF >> "$_cmd"
_remote_trust_bundle=\$(kubectl exec spire-server-0                            \
--namespace "\$SPIRE_NAMESPACE"                                                \
--context "\$GSI_REMOTE_CONTEXT"                                               \
-- spire-server bundle show -format spiffe)

kubectl exec spire-server-0                                                   \
--namespace "\$SPIRE_NAMESPACE"                                                \
--context "\$GSI_CONTEXT"                                                      \
-- spire-server bundle set                                                    \
   -format spiffe                                                             \
   -id "spiffe://\${REMOTE_TRUST_DOMAIN}"                                      \
<<< "\$_remote_trust_bundle"
EOF

  _f_debug "$_cmd"
}
