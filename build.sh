#!/bin/bash -e

cd $(dirname $0)

. utils
. ../../environment

PROJECT=$(osc status | sed -n '1 { s/.* //; p; }')

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
kind: BuildConfig
apiVersion: v1beta1
metadata:
  name: reverseproxy
  labels:
    service: reverseproxy
    function: frontend
triggers:
- type: generic
  generic:
    secret: secret
parameters:
  strategy:
    type: STI
    stiStrategy:
      image: docker.io/cicddemo/sti-httpd
  source:
    type: Git
    git:
      ref: master
      uri: http://gogs.$INFRA/$PROJECT/reverseproxy
  output:
    to:
      name: reverseproxy
EOF
