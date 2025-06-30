#!/usr/bin/env bash
function deck_istio_sidecar {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_SIDECAR_ENABLED=enabled
  export GSI_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio_sidecar exec_telemetry_defaults exec_kgateway_crds exec_helloworld_app)
}

function deck_istio_ambient {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_AMBIENT_ENABLED=enabled
  export GSI_APP_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio_ambient exec_telemetry_defaults exec_kgateway_crds exec_helloworld_app)
}

function deck_istio_mc_ambient {
  export GSI_CLUSTER=$1
  export GSI_CONTEXT=$2
  export GSI_AMBIENT_ENABLED=enabled
  export GSI_EW_SIZE=1
  export GSI_APP_SIZE=1
  export GSI_TRAFFIC_DISTRIBUTION=Any
  export GSI_DECK=(exec_istio_secrets exec_istio_ambient exec_kgateway_crds exec_kgateway_eastwest exec_helloworld_app)
}

function deck_kgateway_eastwest_link {
  export GSI_CONTEXT1=$1
  export GSI_CLUSTER1=$2
  export GSI_NETWORK1=$3
  export GSI_CONTEXT2=$4
  export GSI_DECK=(exec_kgateway_ew_link)
}

function deck_kgateway_ingress_gateway {
  export GSI_CONTEXT=$1
  export GSI_APP_SERVICE_NAMESPACE=$2
  export GSI_APP_SERVICE_NAME=$3
  export GSI_APP_SERVICE_PORT=$4
  export GSI_KGATEWAY_INGRESS_SIZE=1
  export GSI_DECK=(exec_external_dns_for_pihole exec_kgateway_ingress_gateway exec_kgateway_httproute exec_kgateway_reference_grant)
}
