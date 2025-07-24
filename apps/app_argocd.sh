#!/usr/bin/env bash
function exec_argocd_server {
  local _context _cluster
  _cluster=$1
  _context=$2

  while getopts "c:x:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      c)
        _cluster=$OPTARG ;;
      x)
        _context=$OPTARG ;;
    esac
  done

  [[ -z $_context ]] && _context="$_cluster"

  if is_create_mode; then
    $DRY_RUN helm upgrade --install argocd argo/argo-cd                       \
    --kube-context "$_context"                                                \
    --namespace "$ARGOCD_NAMESPACE"                                           \
    --create-namespace                                                        \
    --values <(jinja2                                                         \
               -D cluster="$_cluster"                                         \
               -D tldn="$TLDN"                                                \
               "$TEMPLATES"/helm.argocd.yaml.j2 )                             \
    --wait
  else
    $DRY_RUN helm uninstall argocd                                            \
    --kube-context "$_context"                                                \
    --namespace "$ARGOCD_NAMESPACE"
  fi
}

function exec_argocd_cluster {
  local _manifest="$MANIFESTS/argocd.secret.cluster.${GSI_CLUSTER}.yaml"

  local _cluster_server _cert_data _key_data _ca_data _k8s_user _k8s_cluster

  if [[ $(kubectl config get-contexts "$GSI_CONTEXT" --no-headers=true | awk '{print $1}') == '*' ]]; then
    _k8s_user=$(kubectl config get-contexts "$GSI_CONTEXT" --no-headers=true | awk '{print $4}')
    _k8s_cluster=$(kubectl config get-contexts "$GSI_CONTEXT" --no-headers=true | awk '{print $3}')
  else
    _k8s_user=$(kubectl config get-contexts "$GSI_CONTEXT" --no-headers=true | awk '{print $3}')
    _k8s_cluster=$(kubectl config get-contexts "$GSI_CONTEXT" --no-headers=true | awk '{print $2}')
  fi

  _cluster_server=https://"$(kubectl --context "$GSI_CONTEXT" get nodes "k3d-${GSI_CLUSTER}-server-0" -o jsonpath='{.status.addresses[0].address}')":6443

  _ca_data=$(
    kubectl config view                                                       \
    --raw=true                                                                \
    -o jsonpath='{.clusters[?(@.name == "'"$_k8s_cluster"'")].cluster.certificate-authority-data}')

  _cert_data=$(
    kubectl config view                                                       \
    --raw=true                                                                \
    -o jsonpath='{.users[?(@.name == "'"$_k8s_user"'")].user.client-certificate-data}')

  _key_data=$(
    kubectl config view                                                       \
    --raw=true                                                                \
    -o jsonpath='{.users[?(@.name == "'"$_k8s_user"'")].user.client-key-data}')

  jinja2 -D cluster="$GSI_CLUSTER"                                            \
         -D cluster_server="$_cluster_server"                                 \
         -D cluster_server="$_cluster_server"                                 \
         -D cert_data="$_cert_data"                                           \
         -D key_data="$_key_data"                                             \
         -D ca_data="$_ca_data"                                               \
      "$TEMPLATES"/argocd.secret.cluster.manifest.yaml.j2                     \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$ARGOCD_CONTEXT"                                                 \
  -f "$_manifest" 
}
