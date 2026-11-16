#Atualizar imagens e recriar os contentores.
. "$PSScriptRoot\_comum.ps1"
docker compose pull
docker compose up -d
docker image prune -f
$cfg = Ler-Env
if ($cfg['GPU'] -eq 'amd') { Write-Host 'Nota: o Ollama (AMD) atualiza-se pela própria aplicação ou com: winget upgrade Ollama.Ollama' }
