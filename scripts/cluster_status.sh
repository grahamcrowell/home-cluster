#!/usr/bin/env bash
# shellcheck disable=SC2086
# shellcheck disable=SC2016

# bootstrap status of cluster

DEBUG=${DEBUG:-false}
if [[ $DEBUG != false ]]; then
    DEBUG=true
fi

info() { printf "INFO %s\n" "$*" >&2; }
debug() {
    if [[ $DEBUG == true ]]; then
        printf "DEBUG %s\n" "$*" >&2
    fi
}
action_required() { printf "ACTION REQUIRED %s\n" "$*" >&2; return 1; }
warning() { printf "WARNING %s\n" "$*" >&2; }
error() { printf "ERROR %s\n" "$*" >&2; }

function node_ping() {
    IP=$1
    debug "Pinging $IP"
    if ping -c 1 $IP | grep '1 packets received, 0.0% packet loss' >/dev/null; then
        info "$IP ping succeeded"
        return 0
    fi
    warning "$IP ping failed"
    action_required "Ensure $IP node is powered on"
}

function config_applied() {
    IP=$1
    debug "Checking if config has been applied to $IP"
    if talosctl -n $IP dmesg >/dev/null 2>&1; then
        info "$IP talos config has been applied"
        return 0
    fi
    warning "$IP talos config has not been applied"
    action_required "Run talosctl config-apply on $IP"
    return 1
}

function bootstrap_sent() {
    INIT_NODE_IP=$1
    debug "Checking if bootstrap request has been sent to $INIT_NODE_IP"
    if talosctl -n $INIT_NODE_IP dmesg | grep -F '[talos] bootstrap request received' >/dev/null 2>&1; then
        info "$INIT_NODE_IP bootstrap request already sent"
        return 0
    fi
    warning "$INIT_NODE_IP bootstrap request not yet sent"
    return 1
}

function cilium_status() {
    if kubectl get nodes -o json | jq -e '.items[].status.conditions[] | select(.reason=="CiliumIsUp")' >/dev/null; then
        info "Cilium is healthy"
        return 0
    fi
    warning "Cilium is not healthy"
    action_required "Install Cilium"
    return 1
}

function cluster_status() {
    info "Nodes: $(kubectl get nodes -o json | jq -e '.items | length')"
    n=$(kubectl get nodes -o json | jq -e '.items | length')
    for i in $(seq 0 $((n - 1))); do
        node=$(kubectl get nodes -o json | jq -e ".items[$i].metadata.name" | tr -d '"')
        info "Node: $node IP: $(kubectl get nodes -o json | jq -er ".items[$i].status.addresses[] | select(.type==\"InternalIP\") | .address")"
        info "$(kubectl get nodes -o json | jq -er ".items[$i].status.conditions[] | select(.reason==\"KubeletReady\") | .message")"
        info "$(kubectl get nodes -o json | jq -er ".items[$i].status.conditions[] | select(.reason==\"CiliumIsUp\") | .message")"
    done
    return 1
}


function main() {
    set -e
    CP0_IP="192.168.4.10"
    CP1_IP="192.168.4.11"
    CP2_IP="192.168.4.12"
    INIT_NODE_IP=$CP0_IP

    node_ping $INIT_NODE_IP
    config_applied $INIT_NODE_IP
    bootstrap_sent $INIT_NODE_IP
    node_ping $CP1_IP
    node_ping $CP2_IP
    config_applied $CP1_IP
    config_applied $CP2_IP
    cluster_status

    cilium_status

    flux check --pre
    flux check
}

main
