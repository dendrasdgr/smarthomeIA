#Cópia para fora do PC (disco externo ou NAS).
#Os modelos (Ollama, Whisper, Piper) não precisam de backup: voltam a descarregar-se.
#O essencial: docker-compose*.yml, .env, configuração e backups do Home Assistant.
. "$PSScriptRoot\_comum.ps1"
$cfg = Ler-Env

if ($env:BACKUP_DESTINO) { $destino = $env:BACKUP_DESTINO }
elseif ($cfg['BACKUP_DESTINO']) { $destino = $cfg['BACKUP_DESTINO'] }
else { $destino = 'E:\backups\casa' }

#Evita escrever no disco do PC se o disco externo não estiver ligado
$pai = Split-Path -Parent $destino
if (-not $pai -or -not (Test-Path $pai)) {
    Write-Host "ERRO: '$pai' não existe. O disco de backup está ligado?" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $destino | Out-Null
Copy-Item (Join-Path $script:Raiz 'docker-compose*.yml') $destino -Force
if (Test-Path (Join-Path $script:Raiz '.env')) { Copy-Item (Join-Path $script:Raiz '.env') $destino -Force }

$cfgDestino = Join-Path $destino 'homeassistant-config'
New-Item -ItemType Directory -Force -Path $cfgDestino | Out-Null
Copy-Item (Join-Path $script:Raiz 'homeassistant\*.yaml') $cfgDestino -Force

$haBackups = Join-Path $script:Raiz 'homeassistant\backups'
if (Test-Path $haBackups) {
    robocopy $haBackups (Join-Path $destino 'ha-backups') /MIR /NJH /NJS /NP /NFL /NDL | Out-Null
    #robocopy devolve 0-7 em caso de sucesso
    if ($LASTEXITCODE -ge 8) { Write-Host 'ERRO ao copiar os backups do Home Assistant.' -ForegroundColor Red; exit 1 }
}

Write-Host ("Backup concluído em $destino (" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ')')
exit 0
