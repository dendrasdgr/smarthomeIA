#!/usr/bin/env bash
#Secção 17 do guia: cópia para fora do PC (disco externo ou NAS).
#Os modelos (Ollama, Whisper, Piper) não precisam de backup: voltam a descarregar-se.
#O essencial: docker-compose.yml, .env, configuração e backups do Home Assistant.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Destino: variável de ambiente, ou BACKUP_DESTINO do .env
if [ -z "${BACKUP_DESTINO:-}" ] && [ -f "$RAIZ/.env" ]; then
  BACKUP_DESTINO="$(grep -E '^BACKUP_DESTINO=' "$RAIZ/.env" | cut -d= -f2- || true)"
fi
DESTINO="${BACKUP_DESTINO:-/media/$(id -un)/DISCO-BACKUP/casa}"

# Evita escrever no disco do PC se o disco externo não estiver ligado
PAI="$(dirname "$DESTINO")"
if [ ! -d "$PAI" ]; then
  echo "ERRO: $PAI não existe. O disco de backup está ligado? (ver: ls /media/$(id -un))" >&2
  exit 1
fi

mkdir -p "$DESTINO"

rsync -a "$RAIZ"/docker-compose*.yml "$DESTINO/"
[ -f "$RAIZ/.env" ] && rsync -a "$RAIZ/.env" "$DESTINO/"
mkdir -p "$DESTINO/homeassistant-config"
rsync -a "$RAIZ/homeassistant/"*.yaml "$DESTINO/homeassistant-config/"
if [ -d "$RAIZ/homeassistant/backups" ]; then
  rsync -a --delete "$RAIZ/homeassistant/backups/" "$DESTINO/ha-backups/"
fi

echo "Backup concluído em $DESTINO ($(date '+%F %T'))"
