#!/usr/bin/env bash
#Escolhe o tipo de placa gráfica e prepara o .env.
#Uso: bash scripts/00-escolher-gpu.sh [nvidia|amd|none]
#   nvidia -> Whisper e Ollama na GPU (RTX 3060, etc.)
#   amd    -> Ollama na GPU (ROCm); Whisper no CPU
#   none   -> tudo no CPU
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

GPU="${1:-}"
if [ -z "$GPU" ]; then
  echo "Que placa gráfica tem o PC?"
  echo "  1) NVIDIA"
  echo "  2) AMD"
  echo "  3) Nenhuma / só CPU"
  read -r -p "Escolha [1-3]: " op
  case "$op" in
    1) GPU=nvidia ;;
    2) GPU=amd ;;
    3) GPU=none ;;
    *) echo "Opção inválida." >&2; exit 1 ;;
  esac
fi

case "$GPU" in
  nvidia) FICHEIROS="docker-compose.yml:docker-compose.nvidia.yml" ;;
  amd)    FICHEIROS="docker-compose.yml:docker-compose.amd.yml" ;;
  none)   FICHEIROS="docker-compose.yml" ;;
  *) echo "Uso: $0 [nvidia|amd|none]" >&2; exit 1 ;;
esac

#.env a partir do exemplo, com PUID/PGID do utilizador atual
if [ ! -f .env ]; then
  cp .env.example .env
  sed -i "s/^PUID=.*/PUID=$(id -u)/; s/^PGID=.*/PGID=$(id -g)/" .env
  echo "Criado .env (PUID=$(id -u), PGID=$(id -g))."
fi

sed -i "s#^GPU=.*#GPU=$GPU#; s#^COMPOSE_FILE=.*#COMPOSE_FILE=$FICHEIROS#" .env

echo "GPU=$GPU  ->  COMPOSE_FILE=$FICHEIROS"
case "$GPU" in
  nvidia) echo "Próximos passos: 01-drivers-nvidia.sh, 02-docker.sh, 03-nvidia-container-toolkit.sh, 04-arrancar.sh" ;;
  amd)    echo "Próximos passos: 01-drivers-amd.sh, 02-docker.sh, 04-arrancar.sh (o 03 não é preciso)" ;;
  none)   echo "Próximos passos: 02-docker.sh, 04-arrancar.sh (os 01 e 03 não são precisos)" ;;
esac
