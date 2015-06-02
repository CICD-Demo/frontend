#!/bin/bash -e

cd $(dirname $0)

. utils
. ../environment

PROJECT=$(osc status | sed -n '1 { s/.* //; p; }')

osc create -f - <<EOF || true
kind: ImageStream
apiVersion: v1beta1
metadata:
  name: frontend
  labels:
    component: frontend
EOF

osc create -f - <<EOF
kind: List
apiVersion: v1beta3
items:
- kind: DeploymentConfig
  apiVersion: v1beta1
  metadata:
    name: frontend
    labels:
      component: frontend
  triggers:
  - type: ConfigChange
  - type: ImageChange
    imageChangeParams:
      automatic: true
      containerNames:
      - frontend
      from:
        name: frontend
      tag: latest
  template:
    strategy:
      type: Recreate
    controllerTemplate:
      replicas: 1
      replicaSelector:
        component: frontend
      podTemplate:
        desiredState:
          manifest:
            version: v1beta2
            containers:
            - name: frontend
              image: frontend:latest
              ports:
              - containerPort: 80
        labels:
          component: frontend

- kind: Service
  apiVersion: v1beta3
  metadata:
    name: frontend
    labels:
      component: frontend
  spec:
    ports:
    - port: 80
    selector:
      component: frontend
EOF

osc create -f - <<EOF
kind: Route
apiVersion: v1beta1
metadata:
  name: frontend
  labels:
    component: frontend
host: $PROJECT.example.com
serviceName: frontend
EOF
