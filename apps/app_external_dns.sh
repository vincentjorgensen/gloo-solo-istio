#!/usr/bin/env bash
function app_init_external_dns {
  if $EXTERNAL_DNS_ENABLED; then
    exec_gateway_api_crds
    exec_external_dns_for_pihole

    if $MULTICLUSTER_ENABLED; then
      gsi_cluster_swap
      exec_gateway_api_crds
      exec_external_dns_for_pihole
      gsi_cluster_swap
    fi
  fi
}

function exec_external_dns_for_pihole {
  local _manifest="$MANIFESTS/externaldns.pihole.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/externaldns.pihole.manifest.yaml.j2
  local _pihole_server_address

  _pihole_server_address=$(docker inspect pihole | jq -r '.[].NetworkSettings.Networks."'"$DOCKER_NETWORK"'".IPAddress')

  $DRY_RUN kubectl create secret generic pihole-password                      \
  --context "$GSI_CONTEXT"                                                    \
  --namespace "$KUBE_SYSTEM_NAMESPACE"                                        \
  --from-literal EXTERNAL_DNS_PIHOLE_PASSWORD="$(yq -r '.services.pihole.environment.FTLCONF_webserver_api_password' "$K3D_DIR"/pihole.docker-compose.yaml.j2)"

  jinja2 -D pihole_server_address="$_pihole_server_address"                   \
       "$_template"                                                           \
       "$J2_GLOBALS"                                                          \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context="$GSI_CONTEXT"                                                  \
    --namespace "$KUBE_SYSTEM_NAMESPACE"                                      \
    --for=condition=Ready pods -l app=external-dns
  fi
}

function exec_external_dns_for_pihole_via_helm {
  local _manifest="$MANIFESTS/helm.external-dns.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES/helm.external-dns.yaml.j2"
  local _de_manifest="$MANIFESTS/external-dns-${GSI_CLUSTER}/deployment.external-dns.patch.yaml"
  local _de_template="$TEMPLATES"/deployment.external-dns.patch.yaml
  local _kustomize_renderer="$MANIFESTS/external-dns-${GSI_CLUSTER}/kustomize.sh"
  local _kustomization_template="$TEMPLATES"/external-dns.pihole.kustomization.yaml.j2
  local _kustomization="$MANIFESTS/external-dns-${GSI_CLUSTER}/kustomization.yaml"

  local _pihole_server_address
  _pihole_server_address=$(docker inspect pihole | jq -r '.[].NetworkSettings.Networks."'"$DOCKER_NETWORK"'".IPAddress')

  $DRY_RUN kubectl create secret generic pihole-password                       \
  --context "$GSI_CONTEXT"                                                     \
  --namespace "$KUBE_SYSTEM_NAMESPACE"                                         \
  --from-literal EXTERNAL_DNS_PIHOLE_PASSWORD="$(yq -r '.services.pihole.environment.FTLCONF_webserver_api_password' "$K3D_DIR"/pihole.docker-compose.yaml.j2)"

  jinja2 -D pihole_server_address="$_pihole_server_address"                    \
       "$_template"                                                            \
       "$J2_GLOBALS"                                                           \
    > "$_manifest"

  [[ ! -e $(dirname "$_kustomize_renderer") ]] && mkdir "$(dirname "$_kustomize_renderer")"

  cp "$_de_template" "$_de_manifest"

  jinja2                                                                       \
       "$_kustomization_template"                                              \
       "$J2_GLOBALS"                                                           \
  > "$_kustomization"

  cp "$TEMPLATES"/kustomize.sh "$_kustomize_renderer"

  if is_create_mode; then
    $DRY_RUN helm upgrade -i external-dns external-dns/external-dns            \
    --version "$EXTERNAL_DNS_VER"                                              \
    --kube-context="$GSI_CONTEXT"                                              \
    --namespace "$KUBE_SYSTEM_NAMESPACE"                                       \
    --values "$_manifest"                                                      \
    --post-render "$_kustomize_renderer"                                       \
    --wait
  fi
}
