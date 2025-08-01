#!/usr/bin/env bash

function app_init_aws {
  if $AWS_ENABLED; then
    if $CERT_MANAGER_ENABLED; then
      exec_initialize_root_pca
    fi
  fi
}

function exec_initialize_root_pca {
  local _ca_manifest="$MANIFESTS/pca_ca_config_root_ca.json"
  local _ca_csr="$MANIFESTS/root-ca.csr"
  local _ca_pem="$MANIFESTS/root-ca.pem"

  ROOT_CERT_VALIDITY_IN_DAYS=3650

  if [[ $DRY_RUN == echo ]]; then
    echo "_ca_manifest=$_ca_manifest"
    echo "_ca_csr=$_ca_csr"
    echo "_ca_pem=$_ca_pem"
    echo "ROOT_CERT_VALIDITY_IN_DAYS=$ROOT_CERT_VALIDITY_IN_DAYS"
  fi
  
  cp "$TEMPLATES"/pca_ca_config_root_ca.json                                  \
     "$_ca_manifest"

  echo '#'"Create root private certificate authority (CA)"
  # https://docs.aws.amazon.com/cli/latest/reference/acm-pca/create-certificate-authority.html
  if [[ $DRY_RUN == echo ]]; then
    cat <<'EOF'
    ROOT_CAARN=$(aws acm-pca create-certificate-authority                     \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-configuration file://$_ca_manifest                \
    --certificate-authority-type "ROOT"                                       \
    --idempotency-token 01234567                                              \
    --output json                                                             \
    --tags Key=Name,Value=RootCA                                             |\
    jq -r '.CertificateAuthorityArn')
EOF
  else
    ROOT_CAARN=$(aws acm-pca create-certificate-authority                     \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-configuration file://"$_ca_manifest"              \
    --certificate-authority-type "ROOT"                                       \
    --idempotency-token 01234567                                              \
    --output json                                                             \
    --tags Key=Name,Value=RootCA                                             |\
    jq -r '.CertificateAuthorityArn')
  fi
  echo '#'"Sleep for 15 seconds while CA creation completes"
  $DRY_RUN sleep 15
  echo '#'"ROOT_CAARN=${ROOT_CAARN}"

  echo '#'"Download Root CA CSR from AWS"
  # https://docs.aws.amazon.com/cli/latest/reference/acm-pca/get-certificate-authority-csr.html
  if [[ $DRY_RUN == echo ]]; then
    cat <<'EOF'
    aws acm-pca get-certificate-authority-csr                                 \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --output text > "$_ca_csr"
EOF
  else
    aws acm-pca get-certificate-authority-csr                                 \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --output text > "$_ca_csr"
  fi

  echo '#'"Issue Root Certificate. Valid for $ROOT_CERT_VALIDITY_IN_DAYS days"
  # https://docs.aws.amazon.com/cli/latest/reference/acm-pca/issue-certificate.html
  if [[ $DRY_RUN == echo ]]; then
    cat <<'EOF'
    ROOT_CERTARN=$(aws acm-pca issue-certificate                              \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --csr fileb://"$_ca_csr"                                                  \
    --signing-algorithm "SHA256WITHRSA"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
    --template-arn arn:aws:acm-pca:::template/RootCACertificate/V1            \
    --validity Value=${ROOT_CERT_VALIDITY_IN_DAYS},Type="DAYS"                \
    --idempotency-token 1234567                                               \
    --output json                                                            |\
    jq -r '.CertificateArn')
EOF
  else
    ROOT_CERTARN=$(aws acm-pca issue-certificate                              \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --csr fileb://"$_ca_csr"                                                  \
    --signing-algorithm "SHA256WITHRSA"  	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	\
    --template-arn arn:aws:acm-pca:::template/RootCACertificate/V1            \
    --validity Value=${ROOT_CERT_VALIDITY_IN_DAYS},Type="DAYS"                \
    --idempotency-token 1234567                                               \
    --output json                                                            |\
    jq -r '.CertificateArn')
  fi
  echo '#'"Sleep for 15 seconds while cert issuance completes"
  $DRY_RUN sleep 15
  echo '#'"ROOT_CERTARN=${ROOT_CERTARN}"

  echo '#'"Retrieve root certificate from private CA and save locally"
  # https://docs.aws.amazon.com/cli/latest/reference/acm-pca/get-certificate.html
  if [[ $DRY_RUN == echo ]]; then
    cat <<'EOF'
    aws acm-pca get-certificate                                               \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --certificate-arn "$ROOT_CERTARN"                                         \
    --output text > "$_ca_pem"
EOF
  else
    aws acm-pca get-certificate                                               \
    --profile aws                                                             \
    --region us-west-2                                                        \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --certificate-arn "$ROOT_CERTARN"                                         \
    --output text > "$_ca_pem"
  fi

  echo '#'"Import the signed Private CA certificate for the CA specified by the ARN into ACM PCA"
  # https://docs.aws.amazon.com/cli/latest/reference/acm-pca/import-certificate-authority-certificate.html
  if [[ $DRY_RUN == echo ]]; then
    cat <<'EOF'
    aws acm-pca import-certificate-authority-certificate                      \
    --profile aws                                                             \
    --region  us-west-2                                                       \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --certificate fileb://"$_ca_pem"
EOF
  else
    aws acm-pca import-certificate-authority-certificate                      \
    --profile aws                                                             \
    --region  us-west-2                                                       \
    --certificate-authority-arn "$ROOT_CAARN"                                 \
    --certificate fileb://"$_ca_pem"
  fi
}

###
# INTERMEDIATE CERT
###
function create_aws_intermediate_pca {
  local _component=$1
  local _ca_manifest="$MANIFESTS/pca_ca_config_intermediate_ca.${_component}.json"
  local _ca_csr="$MANIFESTS/intermediate_ca.${_component}.csr"
  local _ca_pem="$MANIFESTS/intermediate-cert.${_component}.pem"
  local _cert_chain_pem="$MANIFESTS/intermediate-cert-chain.${_component}.pem"

  SUBORDINATE_CERT_VALIDITY_IN_DAYS=1825

  jinja2 -D component="$_component"                                           \
         "$TEMPLATES/pca_ca_config_intermediate_ca.json.j2"                   \
  > "$_ca_manifest"

  echo '#'"Create Intermediate private certificate authority (CA) for $_component"
  # https://docs.aws.amazon.com/cli/latest/reference/acm-pca/create-certificate-authority.html
  SUBORDINATE_CAARN="$(                                                       \
  aws acm-pca create-certificate-authority                                    \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --certificate-authority-configuration file://"$_ca_manifest"                \
  --certificate-authority-type "SUBORDINATE"                                  \
  --idempotency-token 01234567                                                \
  --tags Key=Name,Value="SubordinateCA-${_component}"                         |
  jq -r '.CertificateAuthorityArn')"
  echo '#'"Sleep for 15 seconds while Intermediate CA creation completes"
  $DRY_RUN sleep 15
  echo '#'"SUBORDINATE_CAARN=$SUBORDINATE_CAARN"

  echo '#'"Download Intermediate CA CSR from AWS"
  # https://docs.aws.amazon.com/cli/latest/reference/acm-pca/get-certificate-authority-csr.html
  $DRY_RUN aws acm-pca get-certificate-authority-csr                          \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --certificate-authority-arn "$SUBORDINATE_CAARN"                            \
  --output text > "$_ca_csr"

  echo '#'"Issue Intermediate Certificate for $_component. Valid for $SUBORDINATE_CERT_VALIDITY_IN_DAYS days"
  SUBORDINATE_CERTARN="$(                                                      \
  aws acm-pca issue-certificate                                               \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --certificate-authority-arn "$ROOT_CAARN"                                   \
  --csr fileb://"$_ca_csr"                                                    \
  --signing-algorithm "SHA256WITHRSA"                                         \
  --template-arn arn:aws:acm-pca:::template/SubordinateCACertificate_PathLen1/V1 \
  --validity Value=${SUBORDINATE_CERT_VALIDITY_IN_DAYS},Type="DAYS"           \
  --idempotency-token 1234567                                                 \
  --output json                                                               |
  jq -r '.CertificateArn')"
  echo '#'"Sleep for 15 seconds while cert issuance completes"
  $DRY_RUN sleep 15
  echo '#'"SUBORDINATE_CERTARN=$SUBORDINATE_CERTARN"

  echo '#'"Retrieve Intermediate certificate from private CA and save locally"
  $DRY_RUN aws acm-pca get-certificate                                        \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --certificate-authority-arn "$ROOT_CAARN"                                   \
  --certificate-arn "$SUBORDINATE_CERTARN"                                    \
  --output json                                                               |
  jq -r '.Certificate' > "$_ca_pem"

  echo '#'"Retrieve Intermediate certificate chain from private CA and save locally"
  $DRY_RUN aws acm-pca get-certificate                                        \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --certificate-authority-arn "$ROOT_CAARN"                                   \
  --certificate-arn "$SUBORDINATE_CERTARN"                                    \
  --output json                                                               |
  jq -r '.CertificateChain' > "$_cert_chain_pem"

  echo '$'"Import the certificate into ACM PCA"
  $DRY_RUN aws acm-pca import-certificate-authority-certificate               \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --certificate-authority-arn "$SUBORDINATE_CAARN"                            \
  --certificate fileb://"$_ca_pem"                                            \
  --certificate-chain fileb://"$_cert_chain_pem"
}

function create_aws_pca_issuer_role {
  local _component=$1
  local _policy_manifest="$MANIFESTS/AWSPCAIssuerPolicy.${_component}.${GSI_CLUSTER}.json"
  local _assume_manifest="$MANIFESTS/AWSPCAAssumeRole.${_component}.${GSI_CLUSTER}.json"

  local _partition _account_id _oidc_issuer

  _partition=$(aws --profile aws --region us-west-2 sts get-caller-identity |jq -r '.Arn'|awk -F: '{print $2}')
  _account_id=$(aws --profile aws --region us-west-2 sts get-caller-identity |jq -r '.Account')
  _oidc_issuer=$(aws eks describe-cluster                                     \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --name "$GSI_CLUSTER"                                                       |
  jq -r '.cluster.identity.oidc.issuer'                                       |
  sed -e 's;https://\(.*\);\1;')

  jinja2 -D ca_arn="$SUBORDINATE_CAARN"                                       \
         "$TEMPLATES/AWSPCAIssuerPolicy.json.j2"                              \
  > "$_policy_manifest"

  jinja2 -D partition="$_partition"                                           \
         -D account_id="$_account_id"                                         \
         -D oidc_issuer="$_oidc_issuer"                                       \
         "$TEMPLATES/AWSPCAAssumeRole.json.j2"                                \
  > "$_assume_manifest"

  AWS_PCA_POLICY_ARN=$(aws iam create-policy                                  \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --policy-name AWSPCAIssuerPolicy-"$_component-$GSI_CLUSTER-$UTAG"           \
  --policy-document file://"$_policy_manifest"                                \
  --output json | jq -r '.Policy.Arn')
  echo '#'"AWS_PCA_POLICY_ARN=$AWS_PCA_POLICY_ARN"

  AWS_PCA_ROLE_ARN=$(aws iam create-role                                      \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --role-name "$GSI_CLUSTER"-pca-issuer                                       \
  --assume-role-policy-document file://"$_assume_manifest"                    \
  --output json | jq -r '.Role.Arn')
  echo '#'"AWS_PCA_ROLE_ARN=$AWS_PCA_ROLE_ARN"

  aws iam attach-role-policy                                                  \
  --profile aws                                                               \
  --region us-west-2                                                          \
  --role-name "$GSI_CLUSTER"-pca-issuer                                       \
  --policy-arn "$AWS_PCA_POLICY_ARN"
}

function exec_aws_pca_serviceaccount {
    $DRY_RUN kubectl "$GSI_MODE" serviceaccount aws-pca-issuer                \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$CERT_MANAGER_NAMESPACE"

    $DRY_RUN kubectl annotate serviceaccount aws-pca-issuer                   \
    "eks.amazonaws.com/role-arn=${AWS_PCA_ROLE_ARN}"                          \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "$CERT_MANAGER_NAMESPACE"
}

function exec_aws_pca_privateca_issuer {
  if is_create_mode; then
    $DRY_RUN helm upgrade --install aws-pca-issuer awspca/aws-privateca-issuer \
    --version "$AWSPCA_ISSUER_VER"                                            \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$CERT_MANAGER_NAMESPACE"                                     \
    --set serviceAccount.create=false                                         \
    --set serviceAccount.name="aws-pca-issuer"                                \
    --set image.tag="$AWSPCA_ISSUER_VER"                                      \
    --set podLabels.app=aws-pca-issuer                                        \
    --wait
  else
    $DRY_RUN helm uninstall aws-pca-issuer                                    \
    --kube-context="$GSI_CONTEXT"                                             \
    --namespace "$CERT_MANAGER_NAMESPACE"
  fi

  if is_create_mode; then
    $DRY_RUN sleep 1
    $DRY_RUN kubectl wait                                                     \
    --context "$GSI_CONTEXT"                                                  \
    --namespace "CERT_MANAGER_NAMESPACE"                                      \
    --for=condition=Ready pods -l app=aws-pca-issuer
  fi
}

function create_aws_pca_issuer {
  _component=$1
  _namespace=$2
  local _manifest="$MANIFESTS"/awspca_issuer."$_component"."$_namespace"."$GSI_CLUSTER".yaml

  jinja2 -D component="$_component"                                           \
         -D namespace="$_namespace"                                           \
         -D ca_arn="$SUBORDINATE_CAARN"                                       \
         -D ca_region="us-west-2"                                             \
         "$TEMPLATES"/awspca_issuer.manifest.yaml.j2                          \
  > "$_manifest"

  $DRY_RUN kubectl "$GSI_MODE"                                                \
  --context "$GSI_CONTEXT"                                                    \
  -f "$_manifest"
}
