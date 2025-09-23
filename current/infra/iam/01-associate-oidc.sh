#!/bin/bash
set -euo pipefail

# Variablen
CLUSTER="nextcloudcluster"
REGION="eu-central-1"

echo " OIDC Provider für Cluster $CLUSTER in $REGION prüfen/anlegen ..."
eksctl utils associate-iam-oidc-provider \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --approve

echo "OIDC Provider verknüpft."

