#!/usr/bin/env bash
# Drivers para placas AMD Radeon (ROCm). O Ollama exige o driver ROCm v7 no Linux.
#
# Uso:
#   bash scripts/01-drivers-amd.sh                 -> só verifica o estado e mostra o que falta
#   bash scripts/01-drivers-amd.sh URL-DO-DEB      -> instala o amdgpu-install a partir desse .deb
#
# O URL do pacote amdgpu-install muda com cada versão do ROCm, por isso não vai fixo aqui.
# Obtém-no na página oficial (escolhe o teu Ubuntu e o ROCm 7):
#   https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/quick-start.html
set -euo pipefail

if [ "${1:-}" != "" ]; then
  URL="$1"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  sudo apt update && sudo apt upgrade -y
  sudo apt install -y wget
  wget -O "$TMP/amdgpu-install.deb" "$URL"
  sudo apt install -y "$TMP/amdgpu-install.deb"
  sudo apt update
  sudo amdgpu-install --usecase=rocm --no-dkms -y || sudo amdgpu-install --usecase=rocm -y

  sudo usermod -aG render,video "$(id -un)"
  echo
  echo "Driver instalado. Reinicia o PC:  sudo reboot"
  echo "Depois volta a correr este script (sem argumentos) para verificar."
  exit 0
fi

echo "Verificação do driver AMD"
FALTA=0

if [ -e /dev/kfd ]; then
  echo "  [ OK ] /dev/kfd existe"
else
  echo "  [FALTA] /dev/kfd não existe (driver ROCm não instalado ou PC por reiniciar)"; FALTA=1
fi

if [ -d /dev/dri ]; then
  echo "  [ OK ] /dev/dri existe"
else
  echo "  [FALTA] /dev/dri não existe"; FALTA=1
fi

if command -v rocminfo >/dev/null 2>&1; then
  GFX="$(rocminfo 2>/dev/null | grep -o 'gfx[0-9a-f]*' | sort -u | tr '\n' ' ')"
  echo "  [ OK ] rocminfo vê: ${GFX:-nenhuma placa}"
  echo "         (se a tua placa não estiver na lista do Ollama, usa HSA_OVERRIDE_GFX_VERSION no .env)"
else
  echo "  [FALTA] rocminfo não instalado"; FALTA=1
fi

if id -nG "$(id -un)" | grep -qw render && id -nG "$(id -un)" | grep -qw video; then
  echo "  [ OK ] utilizador nos grupos render e video"
else
  echo "  [FALTA] utilizador fora dos grupos render/video:  sudo usermod -aG render,video \$USER  (e novo login)"
  FALTA=1
fi

if [ "$FALTA" -ne 0 ]; then
  echo
  echo "Falta instalar o driver ROCm v7. Obtém o URL do amdgpu-install em:"
  echo "  https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/quick-start.html"
  echo "e corre:  bash scripts/01-drivers-amd.sh URL-DO-DEB"
  exit 1
fi
echo
echo "Tudo pronto para o Ollama usar a placa AMD."
