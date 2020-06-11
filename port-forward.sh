#!/bin/bash
#
#
microk8s.kubectl port-forward --address 127.0.0.1 --namespace default deployment/app2 8081:8081
