#!/usr/bin/env bash
#Passo 3 do guia: drivers da NVIDIA (Ubuntu).
set -euo pipefail

sudo apt update && sudo apt upgrade -y
sudo ubuntu-drivers install

echo
echo "Drivers instalados. É preciso reiniciar o PC:  sudo reboot"
echo "Depois de reiniciar, confirma a placa com:  nvidia-smi"
