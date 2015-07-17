#!/bin/bash -e

cd $(dirname $0)

. utils
. ../../environment

PROJECT=$(oc status | sed -n '1 { s/.* //;s/(//;s/)//;  p; }')

if [ $PROJECT = $PROD ]; then
  ROUTE=monster.$DOMAIN
  REPLICAS=2
else
  ROUTE=monster.$PROJECT.$DOMAIN
  REPLICAS=1
fi

oc create -f - <<EOF || true
kind: ImageStream
apiVersion: v1
metadata:
  name: reverseproxy
  labels:
    service: reverseproxy
    function: frontend
EOF

oc create -f - <<EOF
kind: List
apiVersion: v1
items:
- kind: DeploymentConfig
  apiVersion: v1
  metadata:
    name: reverseproxy
    labels:
      service: reverseproxy
      function: frontend
  spec:
    replicas: $REPLICAS
    selector:
      service: reverseproxy
      function: frontend
    strategy:
      type: Recreate
    template:
      metadata:
        labels:
          service: reverseproxy
          function: frontend
      spec:
        containers:
        - name: reverseproxy
          image: reverseproxy:latest
          ports:
          - containerPort: 80
  triggers:
  - type: ConfigChange
  - type: ImageChange
    imageChangeParams:
      automatic: true
      containerNames:
      - reverseproxy
      from:
        kind: ImageStreamTag
        name: reverseproxy:latest

- kind: Service
  apiVersion: v1
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
  apiVersion: v1
  metadata:
    name: reverseproxy
    labels:
      service: reverseproxy
      function: frontend
  spec:
    host: $ROUTE
    to:
      kind: Service
      name: reverseproxy
EOF
