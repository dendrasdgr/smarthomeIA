#Ligar/desligar o Ollama (por exemplo, para poupar energia).
#Uso: .\scripts\ollama.ps1 parar | iniciar | estado
param([string]$Acao = '')
. "$PSScriptRoot\_comum.ps1"
$cfg = Ler-Env
$gpu = if ($cfg['GPU']) { $cfg['GPU'] } else { 'nvidia' }

if ($gpu -eq 'amd') {
    switch ($Acao) {
        'parar'   { Get-Process -Name 'ollama*' -ErrorAction SilentlyContinue | Stop-Process -Force; Write-Host 'Ollama parado.' }
        'iniciar' { Start-Process -FilePath 'ollama' -ArgumentList 'serve' -WindowStyle Hidden; Write-Host 'Ollama iniciado.' }
        'estado'  { $p = Get-Process -Name 'ollama*' -ErrorAction SilentlyContinue; if ($p) { $p | Format-Table Name, Id } else { Write-Host 'Ollama parado.' } }
        default   { Write-Host 'Uso: ollama.ps1 parar | iniciar | estado'; exit 1 }
    }
} else {
    switch ($Acao) {
        'parar'   { docker compose stop ollama }
        'iniciar' { docker compose start ollama }
        'estado'  { docker compose ps ollama }
        default   { Write-Host 'Uso: ollama.ps1 parar | iniciar | estado'; exit 1 }
    }
}
