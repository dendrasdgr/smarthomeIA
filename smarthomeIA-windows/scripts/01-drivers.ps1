#Verifica o driver da placa gráfica no Windows (não instala nada).
#Uso: .\scripts\01-drivers.ps1
. "$PSScriptRoot\_comum.ps1"
$cfg = Ler-Env
$gpu = if ($cfg['GPU']) { $cfg['GPU'] } else { 'nvidia' }

Write-Host 'Placas gráficas detetadas:'
Get-CimInstance Win32_VideoController | ForEach-Object { Write-Host "  - $($_.Name) (driver $($_.DriverVersion))" }
Write-Host ''
Write-Host "Verificação do driver ($gpu)"

switch ($gpu) {
    'nvidia' {
        if ((Tem-Comando 'nvidia-smi') -and ($(nvidia-smi *> $null; $LASTEXITCODE) -eq 0)) {
            Ok ('nvidia-smi: ' + ((nvidia-smi --query-gpu=name --format=csv,noheader) | Select-Object -First 1))
            Write-Host '  O Docker Desktop (WSL2) usa este driver; não é preciso instalar o NVIDIA Container Toolkit.'
        } else {
            Falha 'nvidia-smi não funciona. Instala o driver mais recente em https://www.nvidia.com/drivers e reinicia o PC.'
        }
    }
    'amd' {
        Write-Host '  Com AMD o Ollama corre diretamente no Windows (o ROCm não funciona em Docker no Windows).'
        if (Tem-Comando 'ollama') { Ok 'Ollama para Windows instalado' }
        else { Falha 'Ollama não instalado. Corre 02-docker.ps1 (instala-o) ou: winget install Ollama.Ollama' }
        Write-Host '  Placas suportadas: https://docs.ollama.com/gpu  (mantém o driver Adrenalin atualizado).'
    }
    'none' { Aviso 'Sem GPU: tudo corre no CPU (a IA será lenta).' }
}
if ($script:Falhou) { exit 1 }
