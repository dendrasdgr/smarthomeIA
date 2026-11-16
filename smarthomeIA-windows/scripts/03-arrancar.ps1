#Arranca os contentores e descarrega o modelo de IA.
#Usa o GPU e o COMPOSE_FILE definidos no .env (ver scripts\00-escolher-gpu.ps1).
. "$PSScriptRoot\_comum.ps1"

if (-not (Test-Path .env)) { & "$PSScriptRoot\00-escolher-gpu.ps1" }
$cfg = Ler-Env
$gpu = if ($cfg['GPU']) { $cfg['GPU'] } else { 'nvidia' }
$modelo = if ($cfg['OLLAMA_MODEL']) { $cfg['OLLAMA_MODEL'] } else { 'qwen3:8b' }

Write-Host "Configuração: GPU=$gpu  ($($cfg['COMPOSE_FILE']))"

if (-not (Docker-Pronto)) {
    Write-Host 'ERRO: o Docker não responde. Abre o Docker Desktop e espera que fique "Running".' -ForegroundColor Red
    exit 1
}

if ($gpu -eq 'nvidia') {
    docker run --rm --gpus all ubuntu nvidia-smi *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'ERRO: os contentores não veem a GPU NVIDIA. Atualiza o driver NVIDIA do Windows e confirma que o Docker Desktop usa o backend WSL2.' -ForegroundColor Red
        exit 1
    }
}
if ($gpu -eq 'amd' -and -not (Tem-Comando 'ollama')) {
    Write-Host 'ERRO: o Ollama para Windows não está instalado (winget install Ollama.Ollama).' -ForegroundColor Red
    exit 1
}

docker compose up -d
if ($LASTEXITCODE -ne 0) { Write-Host 'ERRO: docker compose up falhou.' -ForegroundColor Red; exit 1 }

Write-Host 'A esperar pelo Ollama...'
$pronto = $false
for ($i = 0; $i -lt 60; $i++) {
    Ollama-Cmd $gpu @('list') *> $null
    if ($LASTEXITCODE -eq 0) { $pronto = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $pronto) {
    Write-Host 'ERRO: o Ollama não respondeu. Com AMD, abre a aplicação Ollama (ícone na bandeja) e volta a correr este script.' -ForegroundColor Red
    exit 1
}

Write-Host "A descarregar o modelo $modelo ..."
Ollama-Cmd $gpu @('pull', $modelo)

Write-Host ''
Write-Host 'Pronto. Abre http://localhost:8123 (ou http://IP-DO-PC:8123 noutro dispositivo) para a configuração inicial do Home Assistant.'
Write-Host 'Para confirmar que a IA usa a placa:  .\scripts\verificar.ps1 -GpuTeste'
Write-Host 'Para ver os logs:  docker compose logs -f'
