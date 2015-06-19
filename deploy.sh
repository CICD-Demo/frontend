#!/bin/bash -e

cd $(dirname $0)

. utils
. ../../environment

PROJECT=$(osc status | sed -n '1 { s/.* //; p; }')

if [ $PROJECT = $PROD ]; then
  ROUTE=monster.$DOMAIN
  REPLICAS=2
else
  ROUTE=monster.$PROJECT.$DOMAIN
  REPLICAS=1
fi

osc create -f - <<EOF || true
kind: ImageStream
apiVersion: v1beta1
metadata:
  name: reverseproxy
  labels:
    service: reverseproxy
    function: frontend
EOF

osc create -f - <<EOF
kind: List
apiVersion: v1beta3
items:
- kind: DeploymentConfig
  apiVersion: v1beta1
  metadata:
    name: reverseproxy
    labels:
      service: reverseproxy
      function: frontend
  triggers:
  - type: ConfigChange
  - type: ImageChange
    imageChangeParams:
      automatic: true
      containerNames:
      - reverseproxy
      from:
        name: reverseproxy
      tag: latest
  template:
    strategy:
      type: Recreate
    controllerTemplate:
      replicas: $REPLICAS
      replicaSelector:
        service: reverseproxy
        function: frontend
      podTemplate:
        desiredState:
          manifest:
            version: v1beta2
            containers:
            - name: reverseproxy
              image: reverseproxy:latest
              ports:
              - containerPort: 80
        labels:
          service: reverseproxy
          function: frontend

- kind: Service
  apiVersion: v1beta3
  metadata:
    name: reverseproxy
    labels:
      service: reverseproxy
      function: frontend
  spec:
    ports:
    - port: 80
    selector:
      service: reverseproxy
      function: frontend

- kind: Route
  apiVersion: v1beta1
  metadata:
    name: reverseproxy
    labels:
      service: reverseproxy
      function: frontend
  host: $ROUTE
  serviceName: reverseproxy
EOF
