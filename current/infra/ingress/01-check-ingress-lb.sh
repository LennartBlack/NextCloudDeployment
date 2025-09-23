#!/usr/bin/env bash
set -euo pipefail
NS=ingress-nginx

echo "🔎 Services im Namespace $NS:"
kubectl get svc -n "$NS"

echo -e "\n🔎 LB-DNS:"
kubectl get svc -n "$NS" -l app.kubernetes.io/name=ingress-nginx \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}{"\n"}'

