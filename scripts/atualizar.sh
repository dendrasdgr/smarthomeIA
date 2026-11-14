#!/usr/bin/env bash
#Secção 9 do guia: atualizar imagens e recriar os contentores.
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
docker compose pull
docker compose up -d
docker image prune -f
