#!/usr/bin/env bash
function app_init_keycloak {
  if $KEYCLOAK_ENABLED; then
    exec_keycloak
    exec_initialize_keycloak
  fi
}
function exec_keycloak {
  local _manifest="$MANIFESTS/keycloak.${GSI_CLUSTER}.yaml"

  jinja2 -D namespace="$KEYCLOAK_NAMESPACE"                                   \
         -D version="$KEYCLOAK_VER"                                           \
         "$TEMPLATES"/keycloak.manifest.yaml.j2                               \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 

  if is_create_mode; then
    $DRY_RUN kubectl wait                                                     \
    --context="$GSI_CONTEXT"                                                  \
    --namespace "$KEYCLOAK_NAMESPACE"                                         \
    --for=condition=Ready pods -l app=keycloak
  fi
}

function set_keycloak_token_client_and_secret {
  export KEYCLOAK_TOKEN KEYCLOAK_CLIENT KEYCLOAK_SECRET KEYCLOAK_ID
  KEYCLOAK_TOKEN=$(curl -d "client_id=admin-cli" -d "username=admin"          \
                        -d "password=admin" -d "grant_type=password"          \
                  "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" |
                   jq -r .access_token)

  #shellcheck disable=SC2046
  read -r client token <<<$(curl -H "Authorization: Bearer $KEYCLOAK_TOKEN"   \
                            -X POST -H "Content-Type: application/json"       \
                            -d '{"expiration": 0, "count": 1}'                \
                   "$KEYCLOAK_URL/admin/realms/master/clients-initial-access" |
                   jq -r '[.id, .token] | @tsv')
  KEYCLOAK_CLIENT="$client"

  #shellcheck disable=SC2046
  read -r id secret <<<$(curl -k -X POST                                      \
                              -d "{ \"clientId\": \"${KEYCLOAK_CLIENT}\" }"   \
                              -H "Content-Type:application/json"              \
                              -H "Authorization: bearer ${token}"             \
                  "$KEYCLOAK_URL/realms/master/clients-registrations/default" |
                  jq -r '[.id, .secret] | @tsv')
  KEYCLOAK_SECRET="$secret"
  KEYCLOAK_ID="$id"
  echo '#' KEYCLOAK_TOKEN="$KEYCLOAK_TOKEN"
  echo '#' KEYCLOAK_CLIENT="$KEYCLOAK_CLIENT"
  echo '#' KEYCLOAK_SECRET="$KEYCLOAK_SECRET"
  echo '#' KEYCLOAK_ID="$KEYCLOAK_ID"
}

function exec_initialize_keycloak {
  KEYCLOAK_ENDPOINT=$(kubectl get service keycloak                            \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$KEYCLOAK_NAMESPACE"                                         \
    -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}"):8080
###  KEYCLOAK_HOST=$(echo "${KEYCLOAK_ENDPOINT}" | cut -d: -f1)
###  KEYCLOAK_PORT=$(echo "${KEYCLOAK_ENDPOINT}" | cut -d: -f2)
  KEYCLOAK_URL=http://"${KEYCLOAK_ENDPOINT}"

  set_keycloak_token_client_and_secret # sets KEYCLOAK_TOKEN, KEYCLOAK_CLIENT, KEYCLOAK_SECRET, KEYCLOAK_ID

  # Add allowed redirect URIs
  curl -k -H "Authorization: Bearer $KEYCLOAK_TOKEN" -X PUT                   \
       -H "Content-Type: application/json"                                    \
       -d '{"serviceAccountsEnabled": true, "directAccessGrantsEnabled": true, "authorizationServicesEnabled": true, "redirectUris": ["*"]}' \
       "$KEYCLOAK_URL/admin/realms/master/clients/$KEYCLOAK_ID"

  # Add the group attribute in the JWT token returned by Keycloak
  curl -H "Authorization: Bearer $KEYCLOAK_TOKEN" -X POST                     \
       -H "Content-Type: application/json"                                    \
       -d '{"name": "group", "protocol": "openid-connect", "protocolMapper": "oidc-usermodel-attribute-mapper", "config": {"claim.name": "group", "jsonType.label": "String", "user.attribute": "group", "id.token.claim": "true", "access.token.claim": "true"}}' \
       "$KEYCLOAK_URL/admin/realms/master/clients/$KEYCLOAK_ID/protocol-mappers/models"

  # Create first user
  curl -H "Authorization: Bearer $KEYCLOAK_TOKEN" -X POST                     \
       -H "Content-Type: application/json"                                    \
       -d '{"username": "user1", "email": "user1@example.com", "firstName": "Alice", "lastName": "Doe", "enabled": true, "attributes": {"group": "users"}, "credentials": [{"type": "password", "value": "password", "temporary": false}]}' \
       "$KEYCLOAK_URL/admin/realms/master/users"

  # Create second user
  curl -H "Authorization: Bearer $KEYCLOAK_TOKEN" -X POST                     \
       -H "Content-Type: application/json"                                    \
       -d '{"username": "user2", "email": "user2@solo.io", "firstName": "Bob", "lastName": "Doe", "enabled": true, "attributes": {"group": "users"}, "credentials": [{"type": "password", "value": "password", "temporary": false}]}' \
       "$KEYCLOAK_URL/admin/realms/master/users"
}

function create_keycloak_secret {
  local _namespace=$1
  local _manifest="$MANIFESTS/secret.keycloak.${_namespace}.${GSI_CLUSTER}.yaml"

  ### set_keycloak_token_client_and_secret # sets KEYCLOAK_TOKEN, KEYCLOAK_CLIENT, KEYCLOAK_SECRET, and KEYCLOAK_ID

  jinja2 -D namespace="$_namespace"                                           \
         -D secret="$KEYCLOAK_SECRET"                                         \
         "$TEMPLATES"/secret.keycloak.manifest.yaml.j2                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}

function create_keycloak_extauth_auth_config {
  local _service_name _service_port _namespace
  while getopts "h:m:n:p:s:" opt; do
    # shellcheck disable=SC2220
    case $opt in
      m)
        _service_name=$OPTARG ;;
      s)
        _service_namespace=$OPTARG ;;
      h)
        _httproute_namespace=$OPTARG ;;
      n)
        _namespace=$OPTARG ;;
      p)
        _service_port=$OPTARG ;;
    esac
  done
  local _manifest="$MANIFESTS/auth_config.oauth.${GSI_CLUSTER}.yaml"

  jinja2 -D service_namespace="$_service_namespace"                           \
         -D gateway_address="${_service_name}.${TLDN}"                        \
         -D http_port="$HTTP_INGRESS_PORT"                                    \
         -D client_id="$KEYCLOAK_CLIENT"                                      \
         -D system_namespace="$GLOO_GATEWAY_V2_NAMESPACE"                     \
         -D keycloak_url="$KEYCLOAK_URL"                                      \
         -D gateway_class_name="$GATEWAY_CLASS_NAME"                          \
         -D gateway_namespace="$INGRESS_NAMESPACE"                            \
         -D traffic_policy_name="$TRAFFIC_POLICY_NAME"                        \
         -D httproute_name="${_service_name}-route"                           \
         -D httproute_namespace="${_httproute_namespace}"                     \
         "$TEMPLATES"/auth_config.oauth.manifest.yaml.j2                      \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}
