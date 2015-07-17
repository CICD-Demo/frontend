#!/bin/bash -e

cd $(dirname $0)

. utils
. ../../environment

PROJECT=$(oc status | sed -n '1 { s/.* //;s/(//;s/)//;  p; }')


oc create -f - <<EOF
kind: BuildConfig
apiVersion: v1
metadata:
  name: reverseproxy
  labels:
    service: reverseproxy
    function: frontend
spec:
  triggers:
  - type: generic
    generic:
      secret: secret
  strategy:
    type: Source
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: sti-httpd:latest
        namespace: openshift
  source:
    type: Git
    git:
      ref: master
      uri: http://gogs.$INFRA/$PROJECT/reverseproxy
  output:
    to:
      name: reverseproxy
EOF
