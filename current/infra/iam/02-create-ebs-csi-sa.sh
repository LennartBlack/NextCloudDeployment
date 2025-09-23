#!/bin/bash
set -euo pipefail

# Variablen
CLUSTER="nextcloudcluster"
REGION="eu-central-1"
ROLE_NAME="AmazonEKS_EBS_CSI_DriverRole"
POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

echo " IAM ServiceAccount für EBS CSI Driver erzeugen ..."

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster "$CLUSTER" \
  --region "$REGION" \
  --role-name "$ROLE_NAME" \
  --attach-policy-arn "$POLICY_ARN" \
  --approve \
  --override-existing-serviceaccounts

echo " ServiceAccount + IAM Rolle erstellt/verknüpft."

