#!/usr/bin/env bash
set -euo pipefail

echo "➡️  Ingress NGINX Controller installieren (via Helm)"

# Namespace erstellen
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

# Repo hinzufügen (falls noch nicht vorhanden)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update

# Chart installieren
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.replicaCount=2 \
  --set controller.service.type=LoadBalancer

echo "⏳ Warte auf Service mit EXTERNAL-IP"
kubectl get svc -n ingress-nginx -w

