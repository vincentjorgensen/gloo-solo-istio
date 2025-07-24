#!/usr/bin/env bash
function exec_gme_secrets {
  local _manifest="$MANIFESTS/gme.secret.relay-token.${GSI_CLUSTER}.yaml"

  jinja2 -D gme_secret_token="${GME_SECRET_TOKEN:-token}"                     \
         "$TEMPLATES"/gme.secret.relay-token.manifest.yaml.j2                 \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}

function exec_gloo_platform_crds {
  if is_create_mode; then
    $DRY_RUN helm upgrade -i gloo-platform-crds gloo-platform/gloo-platform-crds \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    --create-namespace                                                        \
    --wait
  else
    $DRY_RUN helm uninstall gloo-platform-crds                                \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"
  fi
}

function exec_gloo_mgmt_server {
  local _manifest="$MANIFESTS/helm.gloo-mgmt-server.${GSI_CLUSTER}.yaml"

  if is_create_mode; then
    jinja2 -D cluster_name="$GSI_CLUSTER"                                     \
           -D verbose="$GME_VERBOSE"                                          \
           -D azure_enabled="$AZURE_FLAG"                                     \
           -D aws_enabled="$AWS_FLAG"                                         \
           -D gcp_enabled="$GCP_FLAG"                                         \
           -D analyzer_enabled="true"                                         \
           -D insights_enabled="true"                                         \
           -D gloo_agent="$GME_MGMT_AGENT_FLAG"                               \
           -D gloo_platform_license_key="$GLOO_PLATFORM_LICENSE_KEY"          \
           "$TEMPLATES"/helm.gloo-mgmt-server.yaml.j2                         \
      > "$_manifest"

    $DRY_RUN helm upgrade -i gloo-platform-mgmt gloo-platform/gloo-platform   \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    --values "$_manifest"                                                     \
    --wait

    export GME_MGMT_CONTEXT=$GSI_CONTEXT
    export GME_MGMT_CLUSTER=$GSI_CLUSTER
  else
    $DRY_RUN helm uninstall gloo-platform-mgmt                                \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"
  fi

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$GLOO_MESH_NAMESPACE"                                        \
    --for=condition=Ready pods --all
  fi
}

function exec_gloo_k8s_cluster {
  local _manifest="$MANIFESTS/gloo.k8s_cluster.${GSI_CLUSTER}.yaml"

  jinja2 -D cluster="$GSI_CLUSTER"                                            \
         "$TEMPLATES"/gloo.k8s_cluster.manifest.yaml.j2                       \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f "$_manifest"
}

function exec_gloo_agent {
  local _manifest="$MANIFESTS/helm.gloo-agent.${GSI_CLUSTER}.yaml"

  GLOO_MESH_SERVER=$(kubectl get svc gloo-mesh-mgmt-server                    \
    --context "$GME_MGMT_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  GLOO_MESH_TELEMETRY_GATEWAY=$(kubectl get svc gloo-telemetry-gateway        \
    --context "$GME_MGMT_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  if is_create_mode; then
    jinja2 -D cluster_name="$GSI_CLUSTER"                                     \
           -D verbose="$GME_VERBOSE"                                          \
           -D insights_enabled="true"                                         \
           -D analyzer_enabled="true"                                         \
           -D gloo_platform_license_key="$GLOO_PLATFORM_LICENSE_KEY"          \
           -D gloo_mesh_server="${GLOO_MESH_SERVER:-GLOO_MESH_SERVER}"        \
           -D gloo_mesh_telemetry_gateway="${GLOO_MESH_TELEMETRY_GATEWAY:-GLOO_MESH_TELEMETRY_GATEWAY}" \
           "$TEMPLATES"/helm.gloo-agent.yaml.j2                               \
      > "$_manifest"

    $DRY_RUN helm upgrade -i gloo-platform-agent gloo-platform/gloo-platform  \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"                                        \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall gloo-platform-agent gloo-platform-crds            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GLOO_MESH_NAMESPACE"
  fi

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$GLOO_MESH_NAMESPACE"                                        \
    --for=condition=Ready pods --all
  fi
}

function exec_gloo_virtual_destination {
  local _manifest="$MANIFESTS/gloo.virtualdestination.${GSI_CLUSTER}.yaml"

  jinja2 -D workspace="$GSI_WORKSPACE_NAME"                                   \
         -D app_service_name="$GSI_APP_SERVICE_NAME"                          \
         -D app_service_port="$GSI_APP_SERVICE_PORT"                          \
         -D tldn="$TLDN"                                                      \
         "$TEMPLATES"/gloo.virtualdestination.manifest.yaml.j2                \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}

function exec_gloo_route_table {
  local _manifest="$MANIFESTS/gloo.routetable.${GSI_CLUSTER}.yaml"

  jinja2 -D workspace="$GSI_WORKSPACE_NAME"                                   \
         -D app_service_name="$GSI_APP_SERVICE_NAME"                          \
         -D mgmt_cluster="$GME_MGMT_CLUSTER"                                  \
         -D tldn="$TLDN"                                                      \
         "$TEMPLATES"/gloo.routetable.manifest.yaml.j2                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}

function exec_gloo_virtual_gateway {
  local _manifest="$MANIFESTS/gloo.virtualgateway.${GSI_CLUSTER}.yaml"

  jinja2 -D gateways_workspace="$GME_GATEWAYS_WORKSPACE"                      \
         -D ingress_gateway_cluster_name="$GSI_GATEWAY_CLUSTER"               \
         -D gateways_namespace="$INGRESS_NAMESPACE"                           \
         -D tldn="$TLDN"                                                      \
         "$TEMPLATES"/gloo.virtualgateway.manifest.yaml.j2                    \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}

function exec_root_trust_policy {
  cp "$TEMPLATES"/gloo.root-trust-policy.manifest.yaml                        \
     "$MANIFESTS"/gloo.root-trust-policy."$GSI_CLUSTER".yaml
  
  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$MANIFESTS"/gloo.root-trust-policy."$GSI_CLUSTER".yaml
}

function exec_gloo_workspacesettings {
  local _manifest="$MANIFESTS/gloo.workspacesettings.${GSI_CLUSTER}.yaml"
  local _ztemp
  _ztemp=$(mktemp)

  echo "import_workspaces:" >> "$_ztemp"
  for ws in "${GSI_WORKSPACESETTTINGS_IMPORT_WORKSPACES[@]}"; do
    echo "- \"$ws\"" >> "$_ztemp"
  done

  echo "export_workspaces:" >> "$_ztemp"
  for ws in "${GSI_WORKSPACESETTTINGS_EXPORT_WORKSPACES[@]}"; do
    echo "- \"$ws\"" >> "$_ztemp"
  done

  cp "$_ztemp" "$_ztemp".yaml

  jinja2 -D name="$GSI_WORKSPACE_NAME"                                        \
         "$TEMPLATES"/gloo.workspacesettings.manifest.yaml.j2                 \
         "$_ztemp".yaml                                                       \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}

function exec_gloo_workspace {
  local _manifest="$MANIFESTS/gloo.workspace.${GSI_CLUSTER}.yaml"
  local _ztemp
  _ztemp=$(mktemp)

  echo "namespaces:" >> "$_ztemp"
  for ns in "${GSI_WORKSPACE_NAMESPACES[@]}"; do
    echo "- $ns" >> "$_ztemp"
  done

  echo "workload_clusters:" >> "$_ztemp"
  for wc in "${GSI_WORKSPACE_CLUSTERS[@]}"; do
    echo "- $wc" >> "$_ztemp"
  done

  cp "$_ztemp" "$_ztemp".yaml

  jinja2 -D name="$GSI_WORKSPACE_NAME"                                        \
         -D namespace="$GLOO_MESH_NAMESPACE"                                  \
         -D mgmt_cluster="$GME_MGMT_CLUSTER"                                  \
         "$TEMPLATES"/gloo.workspace.manifest.yaml.j2                         \
         "$_ztemp".yaml                                                       \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GME_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}
