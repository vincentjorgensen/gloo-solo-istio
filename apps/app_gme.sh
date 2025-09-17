#!/usr/bin/env bash
function app_init_gme {
  if $GME_ENABLED; then
    create_gme_secrets -x "$GSI_MGMT_CONTEXT" -c "$GSI_MGMT_CLUSTER"
    exec_gloo_platform_crds -x "$GSI_MGMT_CONTEXT"
    exec_gloo_mgmt_server
    exec_istio_base -x "$GSI_MGMT_CONTEXT" -c "$GSI_MGMT_CLUSTER"

    if [[ $GSI_MGMT_CLUSTER != "$GSI_CLUSTER" ]]; then
      # First Workload cluster
      exec_gloo_k8s_cluster 
      exec_gme_secrets
      exec_gloo_platform_crds
      exec_gloo_agent
    else
      create_gloo_k8s_cluster -x "$GSI_MGMT_CONTEXT" -c "$GSI_MGMT_CLUSTER"
    fi

    if $MULTICLUSTER_ENABLED; then
      # Second Workload cluster
      gsi_cluster_swap
      exec_gloo_k8s_cluster
      exec_gme_secrets
      exec_gloo_platform_crds
      exec_gloo_agent
      gsi_cluster_swap
    fi

###    if $GME_ENABLED; then
###      create_namespace "$GSI_MGMT_CONTEXT" "$GME_NAMESPACE"
###    fi
  fi
}

function app_init_gme_workspaces {
  if $GME_ENABLED; then
    create_namespace "$GSI_MGMT_CONTEXT" "${GME_GATEWAYS_WORKSPACE}-config"
    create_gloo_workspace -w "$GME_GATEWAYS_WORKSPACE"                        \
                          -n "$EASTWEST_NAMESPACE" -n "$INGRESS_NAMESPACE"    \
                          -c "$GSI_CLUSTER" -c "$GSI_REMOTE_CLUSTER"

    create_namespace "$GSI_MGMT_CONTEXT" "${GME_APPLICATIONS_WORKSPACE}-config"
    create_gloo_workspace -w "$GME_APPLICATIONS_WORKSPACE"                    \
                          -n "$HELLOWORLD_NAMESPACE"                          \
                          -n "$HTTPBIN_NAMESPACE"                             \
                          -n "$CURL_NAMESPACE"                                \
                          -c "$GSI_CLUSTER" -c "$GSI_REMOTE_CLUSTER"

    create_gloo_workspacesettings -w "$GME_GATEWAYS_WORKSPACE"                \
                          -i "$GME_APPLICATIONS_WORKSPACE"                    \
                          -e '*'

    create_gloo_workspacesettings -w "$GME_APPLICATIONS_WORKSPACE"            \
                          -i "$GME_GATEWAYS_WORKSPACE"                        \
                          -e "$GME_GATEWAYS_WORKSPACE"
  fi
}

function create_gme_secrets {
  local _context=$GSI_CONTEXT
  local _cluster=$GSI_CLUSTER

  while getopts "c:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _cluster=$OPTARG ;;
      x)
        _context=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/gme.secret.relay-token.${_cluster}.yaml"
  local _template="$TEMPLATES"/gme.secret.relay-token.manifest.yaml.j2

  _make_manifest "$_template" > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                 \
  --context "$_context"                                                        \
  -f "$_manifest"
}

function exec_gloo_platform_crds {
  local _context=$GSI_CONTEXT

  while getopts "x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      x)
        _context=$OPTARG ;;
    esac
  done

  if is_create_mode; then
    $DRY_RUN helm upgrade -i gloo-platform-crds                               \
                             gloo-platform/gloo-platform-crds                 \
    --version="$GME_VER"                                                      \
    --kube-context="$_context"                                                \
    --namespace="$GME_NAMESPACE"                                              \
    --create-namespace                                                        \
    --wait
  else
    $DRY_RUN helm uninstall gloo-platform-crds                                \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GME_NAMESPACE"        
  fi
}

function exec_gloo_mgmt_server {
  local _manifest="$MANIFESTS/helm.gloo-mgmt-server.${GSI_MGMT_CLUSTER}.yaml"
  local _template="$TEMPLATES"/helm.gloo-mgmt-server.yaml.j2

  if is_create_mode; then
    _make_manifest "$_template" > "$_manifest"

    $DRY_RUN helm upgrade -i gloo-platform-mgmt gloo-platform/gloo-platform    \
    --version="$GME_VER"                                                       \
    --kube-context="$GSI_MGMT_CONTEXT"                                         \
    --namespace="$GME_NAMESPACE"                                               \
    --values "$_manifest"                                                      \
    --wait

    echo '#'"GSI_MGMT_CONTEXT=$GSI_MGMT_CONTEXT"
    echo '#'"GSI_MGMT_CLUSTER=$GSI_MGMT_CLUSTER"
  else
    $DRY_RUN helm uninstall gloo-platform-mgmt                                 \
    --kube-context="$GSI_MGMT_CONTEXT"                                         \
    --namespace="$GME_NAMESPACE"        
  fi

  _wait_for_pods "$GSI_MGMT_CONTEXT" "$GME_NAMESPACE" gloo-mesh-mgmt-server
  _wait_for_pods "$GSI_MGMT_CONTEXT" "$GME_NAMESPACE" gloo-mesh-ui
}

function exec_gloo_k8s_cluster {
  local _manifest="$MANIFESTS/gloo.k8s_cluster.${GSI_CLUSTER}.yaml"
  local _template="$TEMPLATES"/gloo.k8s_cluster.manifest.yaml.j2

  _make_manifest "$_template" > "$_manifest"
  _apply_manifest "$_manifest"
}

function create_gloo_k8s_cluster {
  local _cluster _context
  while getopts "c:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _cluster=$OPTARG ;;
      x)
        _context=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/gloo.k8s_cluster.${_cluster}.yaml"
  local _template="$TEMPLATES"/gloo.k8s_cluster.manifest.yaml.j2

  jinja2                                                                       \
         -D cluster="$_cluster"                                                \
         "$_template"                                                          \
         "$J2_GLOBALS"                                                         \
  > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                 \
  --context "$GSI_MGMT_CONTEXT"                                                \
  -f "$_manifest"
}

function exec_gloo_agent {
  local _manifest="$MANIFESTS/helm.gloo-agent.${GSI_CLUSTER}.yaml"

  GLOO_MESH_SERVER=$(kubectl get svc gloo-mesh-mgmt-server                    \
    --context "$GSI_MGMT_CONTEXT"                                             \
    --namespace="$GME_NAMESPACE"                                              \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  GLOO_MESH_TELEMETRY_GATEWAY=$(kubectl get svc gloo-telemetry-gateway        \
    --context "$GSI_MGMT_CONTEXT"                                             \
    --namespace="$GME_NAMESPACE"                                              \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  if is_create_mode; then
    jinja2 -D cluster_name="$GSI_CLUSTER"                                     \
           -D verbose="$GME_VERBOSE"                                          \
           -D insights_enabled="true"                                         \
           -D analyzer_enabled="true"                                         \
           -D gloo_platform_license_key="$GLOO_PLATFORM_LICENSE_KEY"          \
           -D gloo_mesh_server="${GLOO_MESH_SERVER:-GLOO_MESH_SERVER}"        \
           -D gloo_mesh_telemetry_gateway="${GLOO_MESH_TELEMETRY_GATEWAY:-GLOO_MESH_TELEMETRY_GATEWAY}" \
           -D gme_secret="$GME_SECRET"                                        \
           "$TEMPLATES"/helm.gloo-agent.yaml.j2                               \
      > "$_manifest"

    $DRY_RUN helm upgrade -i gloo-platform-agent gloo-platform/gloo-platform  \
    --version="$GME_VER"                                                      \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GME_NAMESPACE"                                              \
    --values "$_manifest"                                                     \
    --wait
  else
    $DRY_RUN helm uninstall gloo-platform-agent gloo-platform-crds            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace="$GME_NAMESPACE"        
  fi

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$GME_NAMESPACE"                                              \
    --for=condition=Ready pods --all
  fi
}

function create_gloo_virtual_destination {
  while getopts "p:s:w:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      p)
        _service_port=$OPTARG ;;
      s)
        _service_name=$OPTARG ;;
      w)
        _workspace_name=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/gloo.virtualdestination.${_service_name}.${_workspace_name}.${GSI_CLUSTER}.yaml"

  jinja2 -D workspace="$_workspace_name"                                      \
         -D app_service_name="$_service_name"                                 \
         -D app_service_port="$_service_port"                                 \
         -D tldn="$TLDN"                                                      \
         "$TEMPLATES"/gloo.virtualdestination.manifest.yaml.j2                \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}

function create_gloo_route_table {
  local _service_name _workspace_name

  while getopts "s:w:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      s)
        _service_name=$OPTARG ;;
      w)
        _workspace_name=$OPTARG ;;
    esac
  done

  echo "sn $_service_name"

  local _manifest="$MANIFESTS/gloo.routetable.${_workspace_name}.${GSI_CLUSTER}.yaml"

  jinja2 -D workspace="$_workspace_name"                                      \
         -D app_service_name="$_service_name"                                 \
         -D mgmt_cluster="$GSI_MGMT_CLUSTER"                                  \
         -D gateways_workspace="$GME_GATEWAYS_WORKSPACE"                      \
         -D tldn="$TLDN"                                                      \
         "$TEMPLATES"/gloo.routetable.manifest.yaml.j2                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_MGMT_CONTEXT"                                               \
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

  create_namespace "$GSI_MGMT_CONTEXT" "$GME_GATEWAYS_WORKSPACE"-config

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}

function exec_root_trust_policy {
  local _manifest="$MANIFESTS/gloo.root-trust-policy.${GSI_CLUSTER}.yaml"

  jinja2 -D gme_namespace="$GME_NAMESPACE"                                    \
         "$TEMPLATES"/gloo.root-trust-policy.manifest.yaml                    \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}

function create_gloo_workspacesettings {
  local _ztemp
  _ztemp=$(mktemp)

  local _workspace_name _export_workspaces=() _import_workspaces=()
  while getopts "e:i:w:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      i)
        _import_workspaces+=("$OPTARG") ;;
      e)
        _export_workspaces+=("$OPTARG") ;;
      w)
        _workspace_name=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/gloo.workspacesettings.${_workspace_name}.${GSI_MGMT_CLUSTER}.yaml"
  local _template="$TEMPLATES"/gloo.workspacesettings.manifest.yaml.j2

  echo "import_workspaces:" >> "$_ztemp"
  for ws in "${_import_workspaces[@]}"; do
    echo "- \"$ws\"" >> "$_ztemp"
  done

  echo "export_workspaces:" >> "$_ztemp"
  for ws in "${_export_workspaces[@]}"; do
    echo "- \"$ws\"" >> "$_ztemp"
  done

  cp "$_ztemp" "$_ztemp".yaml

  jinja2 -D name="$_workspace_name"                                           \
         "$_template"                                                         \
         "$_ztemp".yaml                                                       \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}

function create_gloo_workspace {
  local _ztemp
  _ztemp=$(mktemp)

  local _workspace_name _namespaces=() _clusters=()

  while getopts "c:n:w:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _clusters+=("$OPTARG") ;;
      n)
        _namespaces+=("$OPTARG") ;;
      w)
        _workspace_name=$OPTARG ;;
    esac
  done

  local _manifest="$MANIFESTS/gloo.workspace.${_workspace_name}.${GSI_MGMT_CLUSTER}.yaml"

  echo "namespaces:" >> "$_ztemp"
  for ns in "${_namespaces[@]}"; do
    echo "- $ns" >> "$_ztemp"
  done

  echo "workload_clusters:" >> "$_ztemp"
  for wc in "${_clusters[@]}"; do
    echo "- $wc" >> "$_ztemp"
  done

  cp "$_ztemp" "$_ztemp".yaml

  jinja2 -D name="$_workspace_name"                                           \
         -D namespace="$GME_NAMESPACE"                                        \
         -D mgmt_cluster="$GSI_MGMT_CLUSTER"                                  \
         "$TEMPLATES"/gloo.workspace.manifest.yaml.j2                         \
         "$_ztemp".yaml                                                       \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_MGMT_CONTEXT"                                               \
  -f "$_manifest" 
}
