#!/usr/bin/env bash
# Create root CA

SPIRE_ROOT_CA_DIR="$(dirname "$0")"
export OPENSSL=/opt/homebrew/opt/openssl@3/bin/openssl
function spire-ca-create-root-ca {
  $OPENSSL genrsa -out "$SPIRE_ROOT_CA_DIR"/root-ca.key 2048
  $OPENSSL req -new -x509 -key "$SPIRE_ROOT_CA_DIR"/root-ca.key -out "$SPIRE_ROOT_CA_DIR"/root-ca.crt -config "$SPIRE_ROOT_CA_DIR"/root-ca.conf -days 3650
  cp "$SPIRE_ROOT_CA_DIR"/root-ca.crt "$SPIRE_ROOT_CA_DIR"/root-ca-bundle.pem
}

function spire-ca-create-cluster-intermediate-ca {
  local _cluster=$1

  mkdir "${_cluster}"  

  $OPENSSL genrsa -out "${_cluster}"/ca-key.pem 2048

  $OPENSSL req -new -key "${_cluster}"/ca-key.pem                             \
              -out "${_cluster}"/ca-csr.pem                                   \
              -config "$SPIRE_ROOT_CA_DIR"/intermediate-ca.conf               \
              -subj "/CN=SPIRE ${_cluster} CA"

  # Sign cluster 1 CSR with root CA
  $OPENSSL x509 -req -in "${_cluster}"/ca-csr.pem                             \
               -CA "$SPIRE_ROOT_CA_DIR"/root-ca.crt                           \
               -CAkey "$SPIRE_ROOT_CA_DIR"/root-ca.key                        \
               -CAcreateserial                                                \
               -out "${_cluster}"/ca-cert.pem                                 \
               -days 1825                                                     \
               -extensions v3_req                                             \
               -extfile "$SPIRE_ROOT_CA_DIR"/intermediate-ca.conf

  cat "${_cluster}"/ca-cert.pem "$SPIRE_ROOT_CA_DIR"/root-ca.crt > "${_cluster}"/cert-chain.pem
}

