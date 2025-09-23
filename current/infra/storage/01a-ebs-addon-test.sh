#!/usr/bin/env bash
set -euo pipefail

CLUSTER=nextcloudcluster
REGION=eu-central-1

echo "Addon-Status:"
eksctl get addons --cluster "$CLUSTER" --region "$REGION" | grep aws-ebs-csi-driver || true

echo -e "\n ServiceAccount-Annotation (IRSA):"
kubectl -n kube-system get sa ebs-csi-controller-sa -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}{"\n"}'

echo -e "\n Pods des EBS-CSI Controllers:"
kubectl -n kube-system get pods -l app=ebs-csi-controller -o wide

echo -e "\n Falls Probleme: Logs (letzte 40 Zeilen)"
kubectl -n kube-system logs deploy/ebs-csi-controller -c ebs-plugin | tail -n 40 || true

