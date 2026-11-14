#!/usr/bin/env bash
#Secção 18 do guia: ligar/desligar o Ollama (por exemplo, para poupar energia).
#Uso: bash scripts/ollama.sh parar | iniciar | estado
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:-}" in
  parar)   docker compose stop ollama ;;
  iniciar) docker compose start ollama ;;
  estado)  docker compose ps ollama ;;
  *) echo "Uso: $0 parar | iniciar | estado" >&2; exit 1 ;;
esac
