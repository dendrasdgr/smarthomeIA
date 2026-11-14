#!/usr/bin/env bash
#Passo 5 do guia: NVIDIA Container Toolkit (dá a GPU aos contentores).
set -euo pipefail

#Só para placas NVIDIA. Com AMD ou sem GPU este passo não é preciso.
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GPU="$(grep -E '^GPU=' "$RAIZ/.env" 2>/dev/null | cut -d= -f2 || true)"
if [ -n "$GPU" ] && [ "$GPU" != "nvidia" ]; then
  echo "GPU=$GPU no .env: o NVIDIA Container Toolkit não é preciso. A sair."
  exit 0
fi

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

echo
echo "A testar se os contentores veem a GPU..."
docker run --rm --gpus all ubuntu nvidia-smi
