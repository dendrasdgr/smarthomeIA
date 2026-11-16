# SmartHome — Home Assistant + IA local (versão Windows)

Versão para **Windows 10/11** do projeto `smarthomeIA` (que é para Ubuntu). Usa **Docker Desktop (WSL2)** e scripts **PowerShell** em vez de `.sh`. Funciona com placa **NVIDIA**, **AMD** ou **sem GPU**.

| Serviço | Função | NVIDIA | AMD | Sem GPU | Porta |
|---|---|---|---|---|---|
| homeassistant | O "cérebro" da casa | — | — | — | 8123 (rede local) |
| whisper | Voz → texto | GPU | **CPU** | CPU | 10300 (só este PC) |
| whisper-cpu | Voz → texto (reserva) | CPU | não existe | não existe | 10301 (só este PC) |
| piper | Texto → voz | CPU | CPU | CPU | 10200 (só este PC) |
| ollama | IA que percebe pedidos naturais | GPU (Docker) | **GPU (Ollama nativo do Windows)** | CPU (Docker) | 11434 |

## O que mudou em relação ao Linux

- **Rede:** o Docker Desktop não tem `network_mode: host` útil no Windows. O Home Assistant publica a porta 8123 e fala com os outros serviços pelo **nome** (`whisper`, `piper`, `ollama`), não por `127.0.0.1`. Ver a tabela de integrações abaixo.
- **NVIDIA:** não há NVIDIA Container Toolkit. O Docker Desktop usa o driver NVIDIA do Windows. Só precisas do driver atualizado.
- **AMD:** o ROCm não funciona em Docker no Windows. O Ollama corre **diretamente no Windows** (instalado com `winget`) e usa a placa AMD; o Home Assistant liga-se a ele por `host.docker.internal`. O Whisper continua no CPU.
- **`COMPOSE_FILE`:** no Windows o separador é `;` (no Linux é `:`).
- **Dados:** modelos do Ollama, Whisper e Piper ficam em volumes do Docker (mais rápidos que pastas do Windows). A configuração do Home Assistant continua em `homeassistant\`.
- **Scripts:** `.sh` → `.ps1`. Removido o `03-nvidia-container-toolkit` (não é preciso); `04-arrancar` passou a `03-arrancar` e `05-tailscale` a `04-tailscale`.

## Estrutura

```
smarthomeIA-windows\
├── docker-compose.yml          # base, funciona sem GPU
├── docker-compose.nvidia.yml   # extra para NVIDIA
├── docker-compose.amd.yml      # extra para AMD (desativa o Ollama em Docker)
├── .env.example                # copiar para .env (o script 00 faz isto)
├── homeassistant\
│   ├── configuration.yaml      # inclui o bloco http: (proxy Tailscale)
│   └── automations.yaml, scenes.yaml, scripts.yaml
└── scripts\                    # instalação, backup, atualização, verificação (.ps1)
```

## Instalação

Abrir a **PowerShell** (como Administrador no passo 02) na pasta do projeto. Na primeira vez, permitir scripts locais:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Depois, por ordem:

```powershell
.\scripts\00-escolher-gpu.ps1          # pergunta: NVIDIA, AMD ou nenhuma (ou: ... amd)
.\scripts\01-drivers.ps1               # só verifica o driver da placa (NVIDIA/AMD)
.\scripts\02-docker.ps1                # instala Docker Desktop (+ Ollama se AMD); depois reiniciar o PC
.\scripts\03-arrancar.ps1              # arranca tudo e descarrega o modelo de IA
.\scripts\verificar.ps1 -GpuTeste
```

Depois do passo 02: abrir o Docker Desktop, esperar por "Running" e ativar em **Settings → General → Start Docker Desktop when you sign in**, para tudo voltar sozinho depois de um reinício.

Antes do passo 03, no router: reservar um IP fixo para o PC (e ligar por cabo, se possível). Na primeira vez que o Windows perguntar sobre a Firewall para o Docker, permitir **redes privadas**, senão outros dispositivos não chegam à porta 8123.

### Notas para AMD

- O Ollama só aceita certas placas (Radeon RX 9000, 7000 e 6000, várias Radeon PRO e algumas Instinct). Lista atual em <https://docs.ollama.com/gpu>. Mantém o driver Adrenalin atualizado.
- A aplicação Ollama tem de estar a correr (ícone na bandeja). Para a deixar arrancar com o Windows, ativar nas definições da própria aplicação.
- Se o Home Assistant não conseguir ligar-se ao Ollama, definir a variável de ambiente `OLLAMA_HOST=0.0.0.0` no Windows e reiniciar o Ollama.
- `.\scripts\verificar.ps1 -GpuTeste` diz se o Ollama está mesmo a usar a GPU. Se estiver no CPU, usar um modelo mais pequeno (`OLLAMA_MODEL` no `.env`).

## Configurar o Home Assistant (na interface)

Abrir `http://localhost:8123` (ou `http://IP-DO-PC:8123` noutro dispositivo), fazer a configuração inicial (recusar partilha de estatísticas) e, em
**Definições → Dispositivos e serviços → Adicionar integração**. Atenção: **os hosts são nomes de serviço, não 127.0.0.1**:

| Integração | Host | Porta | Quando |
|---|---|---|---|
| Wyoming Protocol (Whisper) | `whisper` | 10300 | sempre (GPU em NVIDIA, CPU nos outros casos) |
| Wyoming Protocol (Whisper CPU) | `whisper-cpu` | **10300** | só com NVIDIA (reserva). Dentro do Docker a porta é 10300; 10301 é só a porta publicada no PC |
| Wyoming Protocol (Piper) | `piper` | 10200 | sempre |
| Ollama (NVIDIA / sem GPU) | `http://ollama:11434` | — | Ollama em Docker |
| Ollama (AMD) | `http://host.docker.internal:11434` | — | Ollama nativo do Windows |

Em **Definições → Assistentes de voz**:

- **Casa IA**: voz para texto = faster-whisper; agente = Ollama com controlo do Home Assistant ativado; texto para voz = Piper (voz portuguesa); ativar prioridade ao processamento local de comandos.
- **Casa Simples** (plano B, só com NVIDIA): voz para texto = faster-whisper (CPU, `whisper-cpu`); agente = Home Assistant (local, sem IA); texto para voz = Piper.
- Em **Expor**, escolher os dispositivos que a IA pode controlar.

### Zigbee e outros dispositivos USB

O contentor do Home Assistant no Windows **não vê portas USB/COM diretamente**. Se usas um dongle Zigbee USB, há duas opções: passá-lo ao WSL2 com [usbipd-win](https://github.com/dorssel/usbipd-win) (e acrescentar `devices:` ao serviço `homeassistant`), ou usar um coordenador Zigbee de rede (tipo Ethernet/Wi-Fi), que dispensa USB. Também a descoberta automática de dispositivos por mDNS/UPnP é limitada sem rede host; adicionar por IP funciona.

## HTTPS e acesso remoto (Tailscale)

O browser só deixa usar o microfone em HTTPS. Na consola web do Tailscale → DNS, ativar **MagicDNS** e **HTTPS Certificates**, depois:

```powershell
.\scripts\04-tailscale.ps1
```

O endereço fica `https://nome-do-pc.xxxx.ts.net`. O bloco `http:` com `trusted_proxies` (incluindo os intervalos internos do Docker) já está em `homeassistant\configuration.yaml`.

## Dia a dia

| O quê | Comando |
|---|---|
| Atualizar tudo | `.\scripts\atualizar.ps1` |
| Ver logs | `docker compose logs -f` |
| Verificar estado | `.\scripts\verificar.ps1` |
| Confirmar que a IA usa a GPU | `.\scripts\verificar.ps1 -GpuTeste` |
| Desligar/ligar o Ollama | `.\scripts\ollama.ps1 parar` / `iniciar` |
| Mudar de placa | `.\scripts\00-escolher-gpu.ps1 amd` e depois `docker compose up -d` |

## Backups

1. No Home Assistant: **Definições → Sistema → Backups** → backups automáticos diários (guardar os últimos 7). Ficam em `homeassistant\backups`.
2. Cópia para disco externo: editar `BACKUP_DESTINO` no `.env` (ex.: `E:\backups\casa`), testar `.\scripts\backup-casa.ps1` e agendar (todos os dias às 4h; trocar pelo caminho real da pasta):

```powershell
schtasks /Create /SC DAILY /ST 04:00 /TN "Backup Casa" /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\caminho\smarthomeIA-windows\scripts\backup-casa.ps1"
```

Restaurar num PC novo: repetir os passos de instalação, copiar a pasta, `.\scripts\03-arrancar.ps1` e, na configuração inicial do Home Assistant, escolher **Restaurar a partir de backup**.

## Plano B: se a placa gráfica avariar

- Usar um CPU com gráfica integrada (Intel sem **F** no nome; AMD Ryzen 7000/9000, ou modelos **G** nos mais antigos) e deixar a gráfica integrada ativa na BIOS.
- Com NVIDIA, sem GPU o Whisper (GPU) e o Ollama não arrancam; o resto continua a funcionar. Mudar o satélite para o assistente **Casa Simples**. Para arrancar tudo no CPU: `.\scripts\00-escolher-gpu.ps1 none` e `docker compose up -d`.

## Notas

- O Ollama não tem autenticação: só pôr `OLLAMA_BIND=0.0.0.0` no `.env` se for mesmo preciso.
- O `medium-int8` é um bom equilíbrio no Whisper com GPU NVIDIA; para mais precisão experimentar `turbo` ou `large-v3`. No CPU, `small-int8` é o ponto de partida.
- Num PC Windows a funcionar como servidor, desativar a suspensão automática (Definições → Sistema → Energia) e, se possível, os reinícios automáticos do Windows Update fora de horas.
- HACS e satélites de voz são passos manuais, como na versão Linux.
