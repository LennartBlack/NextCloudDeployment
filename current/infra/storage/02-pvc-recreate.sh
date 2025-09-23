#!/usr/bin/env bash
set -euo pipefail

# Pfade robust ermitteln (unabhängig vom Aufrufverzeichnis)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NS="nextcloud"
PVC_NAME="nextcloud-html"
PVC_FILE="$REPO_ROOT/k8s/nextcloud/pvc.yaml"   # liegt unter k8s/nextcloud/

echo "prüfe PVC-Datei: $PVC_FILE"
if [ ! -f "$PVC_FILE" ]; then
  echo "Datei $PVC_FILE nicht gefunden"; exit 1
fi

echo "entferne storageClassName (Default=gp3 wird genutzt)"
sed -i '/^[[:space:]]*storageClassName:/d' "$PVC_FILE" || true

echo "lösche alten PVC (falls vorhanden)"
kubectl delete pvc "$PVC_NAME" -n "$NS" --ignore-not-found

echo "lege PVC neu an"
kubectl apply -n "$NS" -f "$PVC_FILE"

echo "Warte auf Bound-Status"
for i in {1..40}; do
  PHASE="$(kubectl get pvc "$PVC_NAME" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  echo "  Versuch $i: PVC-Status=${PHASE:-<none>}"
  [ "${PHASE:-}" = "Bound" ] && break
  sleep 5
done

echo "aktueller PVC-Status:"
kubectl get pvc -n "$NS"

echo "Nextcloud-Deployment neu starten (falls vorhanden)"
kubectl -n "$NS" rollout restart deploy/nextcloud || true

echo "Pod-Status:"
kubectl -n "$NS" get pods -o wide

