#!/usr/bin/env bash


kubectl -n rook-ceph get services
kubectl -n rook-ceph get deployments

kubectl -n rook-ceph get cephcluster
kubectl -n rook-ceph describe cephcluster 