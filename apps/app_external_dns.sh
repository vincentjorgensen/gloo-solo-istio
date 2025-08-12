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
  local _pihole_server_address

  _pihole_server_address=$(docker inspect pihole | jq -r '.[].NetworkSettings.Networks."'"$DOCKER_NETWORK"'".IPAddress')

  $DRY_RUN kubectl create secret generic pihole-password                      \
  --context "$GSI_CONTEXT"                                                    \
  --namespace "$KUBE_SYSTEM_NAMESPACE"                                        \
  --from-literal EXTERNAL_DNS_PIHOLE_PASSWORD="$(yq -r '.services.pihole.environment.FTLCONF_webserver_api_password' "$K3D_DIR"/pihole.docker-compose.yaml.j2)"

  jinja2 -D pihole_server_address="$_pihole_server_address"                   \
       "$TEMPLATES"/externaldns.pihole.manifest.yaml.j2                       \
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
