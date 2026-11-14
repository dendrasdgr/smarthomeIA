#!/usr/bin/env bash
#Passo 4 do guia: Docker (Docker Engine, não o Docker Desktop).
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GPU="$(grep -E '^GPU=' "$RAIZ/.env" 2>/dev/null | cut -d= -f2 || true)"

if [ "$GPU" = "nvidia" ]; then
  if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi >/dev/null 2>&1; then
    echo "AVISO: nvidia-smi não funciona. Corre primeiro o 01-drivers-nvidia.sh e reinicia." >&2
  fi
fi

curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$(id -un)"

echo
echo "Docker instalado. Faz logout e login para usar o docker sem sudo."
