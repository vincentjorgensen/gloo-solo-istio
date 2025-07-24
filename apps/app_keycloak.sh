#!/usr/bin/env bash
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

function exec_configure_keycloak {
  export ENDPOINT_KEYCLOAK
  ENDPOINT_KEYCLOAK=$(                                                 \
    kubectl get service keycloak                                              \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$KEYCLOAK_NAMESPACE"                                         \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}'):8080
  export HOST_KEYCLOAK
  HOST_KEYCLOAK=$(echo "${ENDPOINT_KEYCLOAK}" | cut -d: -f1)
  export PORT_KEYCLOAK
  PORT_KEYCLOAK=$(echo "${ENDPOINT_KEYCLOAK}" | cut -d: -f2)
  export KEYCLOAK_URL=http://${ENDPOINT_KEYCLOAK}

  export KEYCLOAK_TOKEN
  KEYCLOAK_TOKEN=$(curl -d "client_id=admin-cli" -d "username=admin" -d "password=admin" -d "grant_type=password" "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" | jq -r .access_token)

  # Create initial token to register the client
  read -r client token <<<$(curl -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d '{"expiration": 0, "count": 1}' $KEYCLOAK_URL/admin/realms/master/clients-initial-access | jq -r '[.id, .token] | @tsv')
  export KEYCLOAK_CLIENT=${client}

  # Register the client
  read -r id secret <<<$(curl -k -X POST -d "{ \"clientId\": \"${KEYCLOAK_CLIENT}\" }" -H "Content-Type:application/json" -H "Authorization: bearer ${token}" ${KEYCLOAK_URL}/realms/master/clients-registrations/default| jq -r '[.id, .secret] | @tsv')
  export KEYCLOAK_SECRET=${secret}

  # Add allowed redirect URIs
  curl -k -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X PUT -H "Content-Type: application/json" -d '{"serviceAccountsEnabled": true, "directAccessGrantsEnabled": true, "authorizationServicesEnabled": true, "redirectUris": ["*"]}' $KEYCLOAK_URL/admin/realms/master/clients/${id}

  # Add the group attribute in the JWT token returned by Keycloak
  curl -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d '{"name": "group", "protocol": "openid-connect", "protocolMapper": "oidc-usermodel-attribute-mapper", "config": {"claim.name": "group", "jsonType.label": "String", "user.attribute": "group", "id.token.claim": "true", "access.token.claim": "true"}}' $KEYCLOAK_URL/admin/realms/master/clients/${id}/protocol-mappers/models

  # Create first user
  curl -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d '{"username": "user1", "email": "user1@example.com", "firstName": "Alice", "lastName": "Doe", "enabled": true, "attributes": {"group": "users"}, "credentials": [{"type": "password", "value": "password", "temporary": false}]}' $KEYCLOAK_URL/admin/realms/master/users

  # Create second user
  curl -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" -X POST -H "Content-Type: application/json" -d '{"username": "user2", "email": "user2@solo.io", "firstName": "Bob", "lastName": "Doe", "enabled": true, "attributes": {"group": "users"}, "credentials": [{"type": "password", "value": "password", "temporary": false}]}' $KEYCLOAK_URL/admin/realms/master/users
}

function create_keycloak_secret {
  local _namespace
  _namespace=$1
  local _manifest="$MANIFESTS/secret.keycloak.${_namespace}.${GSI_CLUSTER}.yaml"

  jinja2 -D namespace="$_namespace"                                           \
         -D secret="$KEYCLOAK_SECRET"                                         \
         "$TEMPLATES"/secret.keycloak.manifest.yaml.j2                        \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}

function exec_gloo_gateway_v2_keycloak_secret {
  create_keycloak_secret "$GLOO_GATEWAY_V2_NAMESPACE"
}

function exec_extauth_keycloak_ggv2_auth_config {
  local _gateway_address
  local _manifest="$MANIFESTS/auth_config.oauth.${GSI_CLUSTER}.yaml"

##  _gateway_address=$(
##    kubectl get svc "$INGRESS_GATEWAY_NAME"                                   \
##    --context "$GSI_CONTEXT"                                                  \
##    --namespace "$INGRESS_NAMESPACE"                                          \
##    -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

  jinja2 -D namespace="$GSI_APP_SERVICE_NAMESPACE"                            \
         -D gateway_address="${GSI_APP_SERVICE_NAME}.${TLDN}"                 \
         -D http_port="$HTTP_INGRESS_PORT"                                    \
         -D client_id="$KEYCLOAK_CLIENT"                                      \
         -D gloo_gateway_v2_namespace="$GLOO_GATEWAY_V2_NAMESPACE"            \
         -D keycloak_url="$KEYCLOAK_URL"                                      \
         -D gateway_class_name="$GATEWAY_CLASS_NAME"                          \
         -D gateway_namespace="$INGRESS_NAMESPACE"                            \
         -D traffic_policy_name="$TRAFFIC_POLICY_NAME"                        \
         -D httproute_name="${GSI_APP_SERVICE_NAME}-route"                    \
         "$TEMPLATES"/auth_config.oauth.manifest.yaml.j2                      \
    > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest" 
}
