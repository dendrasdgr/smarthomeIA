#Funções partilhadas pelos scripts (não correr diretamente).
$ErrorActionPreference = 'Stop'
$script:Raiz = Split-Path -Parent $PSScriptRoot
Set-Location $script:Raiz
$script:Falhou = $false

function Ler-Env {
    $h = @{}
    $f = Join-Path $script:Raiz '.env'
    if (Test-Path $f) {
        foreach ($l in Get-Content $f -Encoding UTF8) {
            if ($l -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') { $h[$Matches[1]] = $Matches[2].Trim() }
        }
    }
    return $h
}

function Definir-Env([string]$chave, [string]$valor) {
    $f = Join-Path $script:Raiz '.env'
    $linhas = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in (Get-Content $f -Encoding UTF8)) { $linhas.Add($l) }
    $achou = $false
    for ($i = 0; $i -lt $linhas.Count; $i++) {
        if ($linhas[$i] -match ('^' + [regex]::Escape($chave) + '=')) { $linhas[$i] = "$chave=$valor"; $achou = $true }
    }
    if (-not $achou) { $linhas.Add("$chave=$valor") }
    #UTF-8 sem BOM (o docker compose lê melhor assim)
    [System.IO.File]::WriteAllLines($f, $linhas, (New-Object System.Text.UTF8Encoding($false)))
}

function Ok([string]$m)    { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Falha([string]$m) { Write-Host "  [FALHA] $m" -ForegroundColor Red; $script:Falhou = $true }
function Aviso([string]$m) { Write-Host "  [AVISO] $m" -ForegroundColor Yellow }

function Tem-Comando([string]$nome) { return [bool](Get-Command $nome -ErrorAction SilentlyContinue) }

function Docker-Pronto {
    if (-not (Tem-Comando 'docker')) { return $false }
    docker info *> $null
    return ($LASTEXITCODE -eq 0)
}

#Corre um comando do Ollama: no Windows (AMD) ou dentro do contentor (NVIDIA / sem GPU)
function Ollama-Cmd([string]$gpu, [string[]]$argumentos) {
    if ($gpu -eq 'amd') { & ollama @argumentos }
    else { & docker exec ollama ollama @argumentos }
}

function Testar-Porta([string]$endereco, [int]$porta) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $t = $c.ConnectAsync($endereco, $porta)
        $ok = $t.Wait(2000) -and $c.Connected
        $c.Close()
        return $ok
    } catch { return $false }
}
