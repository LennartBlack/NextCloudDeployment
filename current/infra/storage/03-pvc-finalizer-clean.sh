#!/usr/bin/env bash
set -euo pipefail

NS="nextcloud"
PVC_NAME="nextcloud-html"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PVC_FILE="$REPO_ROOT/k8s/nextcloud/pvc.yaml"

echo "➡️  skaliere Nextcloud kurz auf 0, damit nichts den PVC hält"
kubectl -n "$NS" scale deploy/nextcloud --replicas=0 || true
kubectl -n "$NS" delete job --all || true

echo "➡️  PVC-Finalizer entfernen (falls vorhanden)"
kubectl -n "$NS" patch pvc "$PVC_NAME" --type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' || true

# Falls der PVC immer noch hängt, PV ermitteln
PV_NAME="$(kubectl -n "$NS" get pvc "$PVC_NAME" -o jsonpath='{.spec.volumeName}' 2>/dev/null || true)"
if [ -n "${PV_NAME:-}" ]; then
  echo "➡️  PV erkannt: $PV_NAME – entferne ggf. PV-Finalizer und lösche PV"
  kubectl patch pv "$PV_NAME" --type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' || true
  kubectl delete pv "$PV_NAME" --ignore-not-found || true
fi

echo "➡️  PVC endgültig löschen (ignoriert, falls schon weg)"
kubectl -n "$NS" delete pvc "$PVC_NAME" --ignore-not-found || true

echo "➡️  PVC neu anlegen aus: $PVC_FILE"
# sicherstellen: pvc.yaml hat keinen storageClassName
sed -i '/^[[:space:]]*storageClassName:/d' "$PVC_FILE" || true
kubectl -n "$NS" apply -f "$PVC_FILE"

echo "⏳ warte auf Bound..."
for i in {1..40}; do
  phase="$(kubectl -n "$NS" get pvc "$PVC_NAME" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  echo "  Versuch $i: $phase"
  [ "$phase" = "Bound" ] && break
  sleep 5
done

echo "📦 PVC-Status:"
kubectl -n "$NS" get pvc

echo "🔁 skaliere Nextcloud wieder hoch"
kubectl -n "$NS" scale deploy/nextcloud --replicas=1 || true
kubectl -n "$NS" get pods -o wide

