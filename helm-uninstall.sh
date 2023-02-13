#!/bin/bash

rm -rf charts
rm -rf Chart.lock
helm uninstall infra --namespace hsv
kubectl delete namespace hsv
kubectl delete namespace logging