#!/usr/bin/env bash
#Verifica se tudo está de pé: GPU, contentores, portas e modelo do Ollama.
#Uso:
#   bash scripts/verificar.sh              -> verificação normal
#   bash scripts/verificar.sh --gpu-teste  -> corre também uma pergunta curta ao modelo
#                                             e mostra se o Ollama a processou na GPU ou no CPU
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
[ -f .env ] && { set -a; . ./.env; set +a; }

GPU="${GPU:-nvidia}"
MODELO="${OLLAMA_MODEL:-qwen3:8b}"
FALHOU=0

ok()    { printf '  [ OK ] %s\n' "$1"; }
falha() { printf '  [FALHA] %s\n' "$1"; FALHOU=1; }
aviso() { printf '  [AVISO] %s\n' "$1"; }

echo "GPU ($GPU)"
case "$GPU" in
  nvidia)
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
      ok "nvidia-smi: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)"
    else
      falha "nvidia-smi não funciona (Whisper GPU e Ollama não vão arrancar; usa o assistente 'Casa Simples')"
    fi ;;
  amd)
    if [ -e /dev/kfd ] && [ -d /dev/dri ]; then
      ok "/dev/kfd e /dev/dri presentes"
    else
      falha "/dev/kfd ou /dev/dri em falta (driver ROCm: bash scripts/01-drivers-amd.sh)"
    fi
    aviso "Com AMD só o Ollama usa a GPU; o Whisper corre no CPU" ;;
  none)
    aviso "Sem GPU: tudo corre no CPU (a IA será lenta)" ;;
esac

echo "Contentores"
SERVICOS="$(docker compose config --services 2>/dev/null)"
for c in $SERVICOS; do
  if [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = "true" ]; then
    ok "$c a correr"
  else
    falha "$c parado"
  fi
done

echo "Portas"
porta() {
  if (exec 3<>"/dev/tcp/127.0.0.1/$2") 2>/dev/null; then ok "$1 (127.0.0.1:$2)"; else falha "$1 (127.0.0.1:$2)"; fi
}
porta "Home Assistant" 8123
if [ "$GPU" = "nvidia" ]; then
  porta "Whisper GPU" 10300
  porta "Whisper CPU" 10301
else
  porta "Whisper CPU" 10300
fi
porta "Piper" 10200
porta "Ollama" 11434

echo "Modelo de IA"
if docker exec ollama ollama list 2>/dev/null | grep -q "$MODELO"; then
  ok "$MODELO descarregado"
else
  falha "modelo $MODELO não encontrado (docker exec ollama ollama pull $MODELO)"
fi

if [ "${1:-}" = "--gpu-teste" ]; then
  echo "Teste da IA (pode demorar na primeira vez)"
  docker exec ollama ollama run "$MODELO" "Responde só: ok" >/dev/null 2>&1
  docker exec ollama ollama ps
  PROC="$(docker exec ollama ollama ps 2>/dev/null | tail -n +2 | head -n1)"
  if [ "$GPU" = "none" ]; then
    aviso "sem GPU configurada"
  elif echo "$PROC" | grep -q "GPU"; then
    ok "o Ollama está a usar a GPU"
  else
    falha "o Ollama está a usar o CPU. Em AMD, vê o HSA_OVERRIDE_GFX_VERSION no .env e 'docker compose logs ollama'"
  fi
fi

exit "$FALHOU"
