#!/usr/bin/env bash
set -euo pipefail
NS=nextcloud
POD="$(kubectl get pods -n "$NS" -l app=nextcloud -o jsonpath='{.items[0].metadata.name}')"

echo "🔎 Beschreibe Pod: $POD"
kubectl describe pod "$POD" -n "$NS" | sed -n '/Events:/,$p'

echo -e "\n🔎 Scheduling-Infos:"
kubectl get pods -n "$NS" -l app=nextcloud -o jsonpath='{.items[0].status.conditions[?(@.type=="PodScheduled")].status}{"\n"}'
kubectl get pods -n "$NS" -l app=nextcloud -o jsonpath='{.items[0].status.conditions[?(@.type=="PodScheduled")].message}{"\n"}' 2>/dev/null || true

echo -e "\n🔎 Node Affinity/Selectors:"
kubectl get deploy nextcloud -n "$NS" -o jsonpath='{.spec.template.spec.nodeSelector}{"\n"}' 2>/dev/null || true
kubectl get deploy nextcloud -n "$NS" -o jsonpath='{.spec.template.spec.affinity}{"\n"}' 2>/dev/null || true

