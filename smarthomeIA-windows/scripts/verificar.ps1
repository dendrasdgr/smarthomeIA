#Verifica se tudo está de pé: GPU, contentores, portas e modelo do Ollama.
#Uso:
#   .\scripts\verificar.ps1             -> verificação normal
#   .\scripts\verificar.ps1 -GpuTeste   -> corre também uma pergunta curta ao modelo
#                                          e mostra se o Ollama a processou na GPU ou no CPU
param([switch]$GpuTeste)
. "$PSScriptRoot\_comum.ps1"
$ErrorActionPreference = 'Continue'
$cfg = Ler-Env
$gpu = if ($cfg['GPU']) { $cfg['GPU'] } else { 'nvidia' }
$modelo = if ($cfg['OLLAMA_MODEL']) { $cfg['OLLAMA_MODEL'] } else { 'qwen3:8b' }

Write-Host "GPU ($gpu)"
switch ($gpu) {
    'nvidia' {
        if ((Tem-Comando 'nvidia-smi') -and ($(nvidia-smi *> $null; $LASTEXITCODE) -eq 0)) {
            Ok ('nvidia-smi: ' + ((nvidia-smi --query-gpu=name --format=csv,noheader) | Select-Object -First 1))
        } else {
            Falha "nvidia-smi não funciona (Whisper GPU e Ollama não vão arrancar; usa o assistente 'Casa Simples')"
        }
    }
    'amd' {
        if (Tem-Comando 'ollama') { Ok 'Ollama para Windows instalado' } else { Falha 'Ollama para Windows não instalado (winget install Ollama.Ollama)' }
        Aviso 'Com AMD só o Ollama usa a GPU; o Whisper corre no CPU'
    }
    'none' { Aviso 'Sem GPU: tudo corre no CPU (a IA será lenta)' }
}

Write-Host 'Docker'
if (Docker-Pronto) { Ok 'Docker Desktop a responder' } else { Falha 'Docker não responde (abre o Docker Desktop)'; exit 1 }

Write-Host 'Contentores'
$servicos = docker compose config --services 2>$null
foreach ($c in $servicos) {
    if ($gpu -eq 'amd' -and $c -eq 'ollama') { continue }
    $estado = docker inspect -f '{{.State.Running}}' $c 2>$null
    if ($estado -eq 'true') { Ok "$c a correr" } else { Falha "$c parado" }
}

Write-Host 'Portas'
function Porta([string]$nome, [int]$p) {
    if (Testar-Porta '127.0.0.1' $p) { Ok "$nome (127.0.0.1:$p)" } else { Falha "$nome (127.0.0.1:$p)" }
}
Porta 'Home Assistant' 8123
if ($gpu -eq 'nvidia') { Porta 'Whisper GPU' 10300; Porta 'Whisper CPU' 10301 } else { Porta 'Whisper CPU' 10300 }
Porta 'Piper' 10200
Porta 'Ollama' 11434

Write-Host 'Modelo de IA'
$lista = Ollama-Cmd $gpu @('list') 2>$null | Out-String
if ($lista -match [regex]::Escape($modelo)) { Ok "$modelo descarregado" } else { Falha "modelo $modelo não encontrado (ollama pull $modelo)" }

if ($GpuTeste) {
    Write-Host 'Teste da IA (pode demorar na primeira vez)'
    Ollama-Cmd $gpu @('run', $modelo, 'Responde só: ok') *> $null
    $ps = Ollama-Cmd $gpu @('ps') 2>$null | Out-String
    Write-Host $ps
    if ($gpu -eq 'none') { Aviso 'sem GPU configurada' }
    elseif ($ps -match 'GPU') { Ok 'o Ollama está a usar a GPU' }
    else { Falha 'o Ollama está a usar o CPU. Atualiza o driver da placa e vê os logs (docker compose logs ollama / %LOCALAPPDATA%\Ollama\server.log)' }
}

if ($script:Falhou) { exit 1 } else { exit 0 }
