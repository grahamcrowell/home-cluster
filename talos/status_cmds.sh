#!/usr/bin/env bash
# shellcheck disable=SC2086

IP=${1:-192.168.4.10}
echo "Status for node at IP: $IP"

ping -c 1 192.168.4.10 | grep '1 packets received, 0.0% packet loss'
# --- before startup
# 1 packets transmitted, 0 packets received, 100.0% packet loss
# --- after startup
# 1 packets transmitted, 1 packets received, 0.0% packet loss

curl -m 1 192.168.4.10:50000 2>&1 | grep 'curl: (52) Empty reply from server'
# --- before startup
# curl: (28) Connection timed out after 1001 milliseconds
# --- after startup
# curl: (52) Empty reply from server

talosctl -n $IP dmesg
# --- before config-apply
# error getting dmesg: rpc error: code = Unavailable desc = last connection error: connection error: desc = "transport: Error while dialing: dial tcp 192.168.4.12:50000: connect: network is unreachable"
# --- after config-apply
# talosctl -n $IP dmesg | grep 'please run `talosctl bootstrap`'

talosctl -n $IP health --wait-timeout 1s
# --- before config-apply
# rpc error: code = Unavailable desc = last connection error: connection error: desc = "transport: Error while dialing: dial tcp 192.168.4.12:50000: connect: network is unreachable"
# --- after config-apply
# discovered nodes: ["192.168.4.10"]
# waiting for etcd to be healthy: ...
# waiting for etcd to be healthy: 1 error occurred:
# 	* 192.168.4.10: service "etcd" not in expected state "Running": current state [Preparing] Running pre state
# healthcheck error: rpc error: code = DeadlineExceeded desc = context deadline exceeded
# --- after bootstrap (and then hangs)
# discovered nodes: ["192.168.4.10"]
# waiting for etcd to be healthy: ...
# waiting for etcd to be healthy: OK
# waiting for etcd members to be consistent across nodes: ...
# waiting for etcd members to be consistent across nodes: OK
# waiting for etcd members to be control plane nodes: ...
# waiting for etcd members to be control plane nodes: OK
# waiting for apid to be ready: ...
# waiting for apid to be ready: OK
# waiting for all nodes memory sizes: ...
# waiting for all nodes memory sizes: OK
# waiting for all nodes disk sizes: ...
# waiting for all nodes disk sizes: OK
# waiting for no diagnostics: ...
# waiting for no diagnostics: OK
# waiting for kubelet to be healthy: ...
# waiting for kubelet to be healthy: OK
# waiting for all nodes to finish boot sequence: ...
# waiting for all nodes to finish boot sequence: OK
# waiting for all k8s nodes to report: ...
# waiting for all k8s nodes to report: can't find expected node with IPs ["192.168.4.10"]
# waiting for all k8s nodes to report: OK
# waiting for all control plane static pods to be running: ...
# waiting for all control plane static pods to be running: missing static pods on node 192.168.4.10: [kube-system/kube-apiserver kube-system/kube-controller-manager kube-system/kube-scheduler]
# waiting for all control plane static pods to be running: OK
# waiting for all control plane components to be ready: ...
# waiting for all control plane components to be ready: can't find expected node with IPs ["192.168.4.10"]
# waiting for all control plane components to be ready: OK
# waiting for all k8s nodes to report ready: ...
# waiting for all k8s nodes to report ready: some nodes are not ready: [cp0]

talosctl -n $IP cluster show
# PROVISIONER           docker
# NAME                  talos-default
# NETWORK NAME
# NETWORK CIDR
# NETWORK GATEWAY
# NETWORK MTU           0
# KUBERNETES ENDPOINT

# NODES:

# NAME   TYPE   IP   CPU   RAM   DISK

talosctl -n $IP conformance kubernetes
# --- after config-apply
# failed to cleanup: Delete "https://192.168.4.10:6443/apis/rbac.authorization.k8s.io/v1/clusterrolebindings/conformance-serviceaccount-role:conformance": dial tcp 192.168.4.10:6443: connect: connection refused
# --- after bootstrap
# running conformance tests version 1.32.0
# running tests: \[Conformance\]
# 2025/02/08 16:19:15 INFO Created Namespace conformance.
# 2025/02/08 16:19:15 INFO Created ServiceAccount conformance-serviceaccount.
# 2025/02/08 16:19:15 INFO Created Clusterrole conformance-serviceaccount:conformance.
# 2025/02/08 16:19:15 INFO Created ClusterRoleBinding conformance-serviceaccount-role:conformance.
# 2025/02/08 16:19:15 INFO Created Pod e2e-conformance-test.
# 2025/02/08 16:19:15 INFO Waiting up to 5m0s for Pod to start...

talosctl -n $IP get members
# --- after config-apply
# NODE           NAMESPACE   TYPE     ID    VERSION   HOSTNAME   MACHINE TYPE   OS               ADDRESSES
# 192.168.4.10   cluster     Member   cp0   2         cp0        controlplane   Talos (v1.9.2)   ["192.168.4.10"]
# --- after bootstrap
# NODE           NAMESPACE   TYPE     ID    VERSION   HOSTNAME   MACHINE TYPE   OS               ADDRESSES
# 192.168.4.10   cluster     Member   cp0   2         cp0        controlplane   Talos (v1.9.2)   ["192.168.4.10"]

echo "check etcd service state"
talosctl -n $IP service etcd
# --- before config-apply
# error listing services: rpc error: code = Unavailable desc = last connection error: connection error: desc = "transport: Error while dialing: dial tcp 192.168.4.10:50000: connect: network is unreachable"
# --- after config-apply
# NODE     192.168.4.10
# ID       etcd
# STATE    Preparing
# HEALTH   ?
# EVENTS   [Preparing]: Running pre state (25m50s ago)
#          [Waiting]: Waiting for service "cri" to be "up" (25m51s ago)
#          [Waiting]: Waiting for service "cri" to be "up", time sync, network, etcd spec (25m59s ago)
#          [Starting]: Starting service (25m59s ago)
# --- after bootstrap
# ODE     192.168.4.10
# ID       etcd
# STATE    Running
# HEALTH   OK
# EVENTS   [Running]: Health check successful (7m37s ago)
#          [Running]: Started task etcd (PID 3052) for container etcd (7m42s ago)
#          [Preparing]: Creating service runner (7m42s ago)
#          [Preparing]: Running pre state (7m42s ago)
#          [Waiting]: Waiting for service "cri" to be "up", time sync, network, etcd spec (7m42s ago)
#          [Starting]: Starting service (7m42s ago)


echo "check etcd membership on each control plane node"
talosctl -n $IP etcd members
# --- after config-apply
# --- nothing but hangs
# --- after bootstrap
# NODE           ID                 HOSTNAME   PEER URLS                   CLIENT URLS                 LEARNER
# 192.168.4.10   9806a7859559874a   cp0        https://192.168.4.10:2380   https://192.168.4.10:2379   false

talosctl -n $IP dmesg

echo "check etcd logs"
talosctl -n $IP logs etcd
# --- after config-apply and bootstrap
# --- nothing exits immediately

echo "check etcd alarms"
talosctl -n $IP etcd alarm list
# --- after config-apply and bootstrap
# --- nothing exits immediately

waiting for all k8s nodes to report schedulable: OK


kubectl get nodes -o json | jq -e '.items[0].status.conditions | min(.lastTransitionTime)'

unset _BOOTSTRAP_SUCCESSFUL
kubectl get nodes -o json | jq -e '.items[0].status.conditions[] | select(.reason=="KubeletReady")' > /dev/null && _BOOTSTRAP_SUCCESSFUL=true
if [ -z "$_BOOTSTRAP_SUCCESSFUL" ]; then
    echo "Kubelet is not ready"
fi
unset _CILIUM_UP
kubectl get nodes -o json | jq -e '.items[0].status.conditions[] | select(.reason=="CiliumIsUp")' > /dev/null && _CILIUM_UP=true
if [ -z "$_CILIUM_UP" ]; then
    echo "Cilium is not up"
fi

