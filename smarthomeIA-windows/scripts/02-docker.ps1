#Instala o Docker Desktop (com WSL2) através do winget. Com AMD instala também o Ollama para Windows.
#Uso: .\scripts\02-docker.ps1   (idealmente numa PowerShell aberta como Administrador)
. "$PSScriptRoot\_comum.ps1"
$cfg = Ler-Env
$gpu = if ($cfg['GPU']) { $cfg['GPU'] } else { 'nvidia' }

if (-not (Tem-Comando 'winget')) {
    Write-Host 'O winget não está disponível. Instala o "App Installer" na Microsoft Store, ou instala o Docker Desktop manualmente:' -ForegroundColor Red
    Write-Host '  https://www.docker.com/products/docker-desktop/'
    exit 1
}

if ($gpu -eq 'nvidia' -and -not (Tem-Comando 'nvidia-smi')) {
    Aviso 'nvidia-smi não encontrado. Instala o driver NVIDIA do Windows (01-drivers.ps1).'
}

if (Tem-Comando 'docker') {
    Ok 'Docker já está instalado'
} else {
    Write-Host 'A instalar o WSL2 (se faltar)...'
    wsl --install --no-distribution 2>&1 | Out-Host
    Write-Host 'A instalar o Docker Desktop...'
    winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
}

if ($gpu -eq 'amd') {
    if (Tem-Comando 'ollama') { Ok 'Ollama para Windows já está instalado' }
    else { winget install -e --id Ollama.Ollama --accept-source-agreements --accept-package-agreements }
}

Write-Host ''
Write-Host 'Feito. Agora:'
Write-Host '  1) Reinicia o PC (o WSL2 e o Docker Desktop pedem isso na primeira instalação).'
Write-Host '  2) Abre o Docker Desktop, aceita os termos e espera que fique "Running".'
Write-Host '  3) Em Settings > General ativa "Start Docker Desktop when you sign in to your computer".'
Write-Host '  4) Corre .\scripts\03-arrancar.ps1'
