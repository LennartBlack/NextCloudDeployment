#!/usr/bin/env bash
set -euo pipefail

# Installiert Helm (Linux x86_64) in AWS CloudShell
TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR"

echo "➡️ Lade Helm herunter …"
curl -sSL https://get.helm.sh/helm-v3.14.4-linux-amd64.tar.gz -o helm.tar.gz

echo "➡️ Entpacke …"
tar -xzf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

echo "✅ Helm Version:"
helm version

echo "🔧 (optional) Bash Completion aktivieren"
helm completion bash | sudo tee /etc/bash_completion.d/helm >/dev/null || true
echo "Starte eine neue Shell oder 'source ~/.bashrc', um Completion zu laden."

