#!/usr/bin/env bash
set -euo pipefail

NS=nextcloud

echo "🔎 PVC:"
kubectl get pvc -n "$NS"

echo -e "\n🔎 Pods (warten bis Ready):"
for i in {1..5}; do
  READY=$(kubectl get pods -n "$NS" -l app=nextcloud -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || true)
  PHASE=$(kubectl get pods -n "$NS" -l app=nextcloud -o jsonpath='{.items[0].status.phase}' 2>/dev/null || true)
  echo "  Versuch $i: phase=${PHASE:-<none>} ready=${READY:-<none>}"
  [ "${READY:-}" = "true" ] && break
  sleep 5
done

echo -e "\n🔎 Services:"
kubectl get svc -n "$NS"

echo -e "\n🔎 Ingress:"
kubectl get ingress -n "$NS"

