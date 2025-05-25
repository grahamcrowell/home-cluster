#!/usr/bin/env bash

kubectl get pods --namespace rook-ceph --output=yaml | yq '.items[] | select(.spec.containers[].resources.requests.cpu | length > 0) | [{"pod":.metadata.name, "namespace":.metadata.namespace, "resources":.spec.containers[].resources.requests.cpu}]' > requests.cpu.yaml
kubectl get pods --namespace rook-ceph --output=yaml | yq '.items[] | select(.spec.containers[].resources.limits.cpu | length > 0) | [{"pod":.metadata.name, "namespace":.metadata.namespace, "resources":.spec.containers[].resources.limits.cpu}]' > limits.cpu.yaml
kubectl get pods --namespace rook-ceph --output=yaml | yq '.items[] | select(.spec.containers[].resources.requests.memory | length > 0) | [{"pod":.metadata.name, "namespace":.metadata.namespace, "resources":.spec.containers[].resources.requests.memory}]' > requests.memory.yaml
kubectl get pods --namespace rook-ceph --output=yaml | yq '.items[] | select(.spec.containers[].resources.limits.memory | length > 0) | [{"pod":.metadata.name, "namespace":.metadata.namespace, "resources":.spec.containers[].resources.limits.memory}]' > limits.memory.yaml


echo "limits.cpu"
kubectl get pods --all-namespaces --output=yaml | yq '.items[].spec.containers[].resources.limits.cpu' | grep -v null | sed 's/\([1-9]\)$/\1000/' | sed 's/m//' | awk '{s+=$1} END {printf "%.0f\n", s}'
echo "requests.cpu"
kubectl get pods --all-namespaces --output=yaml | yq '.items[].spec.containers[].resources.requests.cpu' | grep -v null | sed 's/\([1-9]\)$/\1000/' | sed 's/m//' | awk '{s+=$1} END {printf "%.0f\n", s}'
echo "limits.memory"
kubectl get pods --all-namespaces --output=yaml | yq '.items[].spec.containers[].resources.limits.memory' | grep -v null | sed -e 's/Gi/000/' -e 's/Mi//' | awk '{s+=$1} END {printf "%.0f\n", s}'
echo "requests.memory"
kubectl get pods --all-namespaces --output=yaml | yq '.items[].spec.containers[].resources.requests.memory' | grep -v null | sed -e 's/Gi/000/' -e 's/Mi//' | awk '{s+=$1} END {printf "%.0f\n", s}'

kubectl get pods --namespace rook-ceph --output=yaml | yq '.items[].spec.containers[].resources'

kubectl get pods --all-namespaces --output=yaml | yq '.items[] | {"pod":.metadata.name, "namespace":.metadata.namespace, "resources":.spec.containers[].resources}'