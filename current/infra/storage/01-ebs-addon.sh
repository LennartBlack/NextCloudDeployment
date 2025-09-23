#!/usr/bin/env bash
set -euo pipefail

# Variablen
CLUSTER=nextcloudcluster
REGION=eu-central-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole"

echo "Addon aws-ebs-csi-driver mit IAM Rolle $ROLE_ARN für Cluster $CLUSTER in $REGION konfigurieren ..."

eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster "$CLUSTER" \
  --region "$REGION" \
  --service-account-role-arn "$ROLE_ARN" \
  --force

echo "Prüfe, ob ServiceAccount korrekt verknüpft ist ..."
kubectl get sa ebs-csi-controller-sa -n kube-system -o yaml | grep -A3 annotations || true

echo "EBS-CSI Controller neu starten ..."
kubectl rollout restart deploy/ebs-csi-controller -n kube-system
kubectl -n kube-system get pods -l app=ebs-csi-controller -w

