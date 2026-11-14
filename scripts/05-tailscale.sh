#!/usr/bin/env bash
#Secção 14 do guia: HTTPS e acesso remoto com Tailscale.
#Antes do passo "serve": na consola web do Tailscale -> DNS, ativar MagicDNS e HTTPS Certificates.
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

sudo tailscale up

echo
read -r -p "Já ativaste MagicDNS e HTTPS Certificates na consola do Tailscale? [s/N] " resp
if [[ "${resp,,}" != "s" ]]; then
  echo "Ativa-os e volta a correr este script (ou:  sudo tailscale serve --bg 8123)."
  exit 0
fi

sudo tailscale serve --bg 8123
sudo tailscale serve status

echo
echo "O bloco http: (trusted_proxies) já está em homeassistant/configuration.yaml."
echo "Se o Home Assistant já estava a correr:  docker restart homeassistant"
