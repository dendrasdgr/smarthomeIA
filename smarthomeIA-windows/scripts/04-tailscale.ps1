#HTTPS e acesso remoto com Tailscale.
#Antes do passo "serve": na consola web do Tailscale -> DNS, ativar MagicDNS e HTTPS Certificates.
. "$PSScriptRoot\_comum.ps1"

if (-not (Tem-Comando 'tailscale')) {
    if (-not (Tem-Comando 'winget')) {
        Write-Host 'Instala o Tailscale manualmente: https://tailscale.com/download/windows' -ForegroundColor Red
        exit 1
    }
    winget install -e --id Tailscale.Tailscale --accept-source-agreements --accept-package-agreements
    Write-Host 'Tailscale instalado. Fecha e volta a abrir a PowerShell (para o comando "tailscale" ficar disponível) e corre este script outra vez.'
    exit 0
}

tailscale up

Write-Host ''
$resp = Read-Host 'Já ativaste MagicDNS e HTTPS Certificates na consola do Tailscale? [s/N]'
if ($resp.ToLower() -ne 's') {
    Write-Host 'Ativa-os e volta a correr este script (ou:  tailscale serve --bg 8123).'
    exit 0
}

tailscale serve --bg 8123
tailscale serve status

Write-Host ''
Write-Host 'O bloco http: (trusted_proxies) já está em homeassistant\configuration.yaml.'
Write-Host 'Se o Home Assistant já estava a correr:  docker restart homeassistant'
Write-Host 'Se der erro de permissões, abre a PowerShell como Administrador.'
