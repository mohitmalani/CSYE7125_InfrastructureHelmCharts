#!/bin/bash
cd infra
helm dependency build
helm install infra --create-namespace --namespace hsv .