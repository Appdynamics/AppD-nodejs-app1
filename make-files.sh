#!/bin/bash
#
#
kc=microk8s.kubectl

$kc delete configmap appdynamics-common
$kc delete configmap appdynamics-secrets
$kc delete configmap appd-start-js
$kc delete configmap appd-start-sh

$kc create -f appdynamics-common-configmap.yaml
$kc create -f appdynamics-secrets.yaml
$kc create configmap appd-start-js --from-file=appd-start.js
$kc create configmap appd-start-sh --from-file=appd-start.sh

$kc get configmaps appdynamics-common -o yaml
$kc get configmaps appdynamics-secrets -o yaml
$kc get configmaps appd-start-js -o yaml
$kc get configmaps appd-start-sh -o yaml
