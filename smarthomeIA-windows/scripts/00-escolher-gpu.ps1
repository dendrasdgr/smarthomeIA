#Escolhe o tipo de placa gráfica e prepara o .env.
#Uso: .\scripts\00-escolher-gpu.ps1 [nvidia|amd|none]
#   nvidia -> Whisper e Ollama na GPU (RTX 3060, etc.)
#   amd    -> Ollama nativo do Windows na GPU; Whisper no CPU
#   none   -> tudo no CPU
param([string]$Gpu = '')
. "$PSScriptRoot\_comum.ps1"

if (-not $Gpu) {
    Write-Host 'Que placa gráfica tem o PC?'
    Write-Host '  1) NVIDIA'
    Write-Host '  2) AMD'
    Write-Host '  3) Nenhuma / só CPU'
    $op = Read-Host 'Escolha [1-3]'
    switch ($op) {
        '1' { $Gpu = 'nvidia' }
        '2' { $Gpu = 'amd' }
        '3' { $Gpu = 'none' }
        default { Write-Host 'Opção inválida.' -ForegroundColor Red; exit 1 }
    }
}

switch ($Gpu) {
    'nvidia' { $ficheiros = 'docker-compose.yml;docker-compose.nvidia.yml' }
    'amd'    { $ficheiros = 'docker-compose.yml;docker-compose.amd.yml' }
    'none'   { $ficheiros = 'docker-compose.yml' }
    default  { Write-Host 'Uso: 00-escolher-gpu.ps1 [nvidia|amd|none]' -ForegroundColor Red; exit 1 }
}

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host 'Criado .env a partir do .env.example.'
}

Definir-Env 'GPU' $Gpu
Definir-Env 'COMPOSE_FILE' $ficheiros

Write-Host "GPU=$Gpu  ->  COMPOSE_FILE=$ficheiros"
switch ($Gpu) {
    'nvidia' { Write-Host 'Próximos passos: 01-drivers.ps1, 02-docker.ps1, 03-arrancar.ps1' }
    'amd'    { Write-Host 'Próximos passos: 01-drivers.ps1, 02-docker.ps1 (instala também o Ollama), 03-arrancar.ps1' }
    'none'   { Write-Host 'Próximos passos: 02-docker.ps1, 03-arrancar.ps1' }
}
