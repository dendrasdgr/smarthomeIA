#!/usr/bin/env bash
#Passos 6 e 7 do guia: arrancar os contentores e descarregar o modelo de IA.
#Usa o GPU e o COMPOSE_FILE definidos no .env (ver scripts/00-escolher-gpu.sh).
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

# Sem .env, pergunta qual é a placa
if [ ! -f .env ]; then
  bash scripts/00-escolher-gpu.sh
fi

# shellcheck disable=SC1091
set -a; . ./.env; set +a

echo "Configuração: GPU=${GPU:-?}  (${COMPOSE_FILE:-docker-compose.yml})"

if [ "${GPU:-}" = "amd" ] && [ ! -e /dev/kfd ]; then
  echo "ERRO: /dev/kfd não existe. Instala o driver ROCm: bash scripts/01-drivers-amd.sh" >&2
  exit 1
fi
if [ "${GPU:-}" = "nvidia" ] && ! docker run --rm --gpus all ubuntu nvidia-smi >/dev/null 2>&1; then
  echo "ERRO: os contentores não veem a GPU NVIDIA. Corre o 03-nvidia-container-toolkit.sh" >&2
  exit 1
fi

mkdir -p homeassistant whisper piper ollama
[ "${GPU:-}" = "nvidia" ] && mkdir -p whisper-cpu

docker compose up -d

echo "A esperar pelo Ollama..."
for _ in $(seq 1 60); do
  if docker exec ollama ollama list >/dev/null 2>&1; then break; fi
  sleep 2
done

MODELO="${OLLAMA_MODEL:-qwen3:8b}"
echo "A descarregar o modelo $MODELO ..."
docker exec ollama ollama pull "$MODELO"

echo
echo "Pronto. Abre http://IP-DO-PC:8123 para a configuração inicial do Home Assistant."
echo "Para confirmar que a IA usa a placa:  bash scripts/verificar.sh --gpu-teste"
echo "Para ver os logs:  docker compose logs -f"
