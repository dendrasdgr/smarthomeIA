# SmartHome — Home Assistant + IA local

Base do projeto a partir do guia em `docs/guia-original.txt`. Corre num PC com Ubuntu e Docker, e funciona com placa **NVIDIA**, **AMD** ou **sem GPU**.

| Contentor | Função | NVIDIA | AMD | Sem GPU | Porta (só 127.0.0.1) |
|---|---|---|---|---|---|
| homeassistant | O "cérebro" da casa (rede host) | — | — | — | 8123 |
| whisper | Voz → texto | GPU | **CPU** | CPU | 10300 |
| whisper-cpu | Voz → texto (reserva) | CPU | não existe | não existe | 10301 |
| piper | Texto → voz | CPU | CPU | CPU | 10200 |
| ollama | IA que percebe pedidos naturais | GPU | GPU (ROCm) | CPU | 11434 |

Com AMD, o Whisper corre no CPU porque o faster-whisper não tem suporte ROCm. Só o Ollama (a IA) usa a placa.

## Estrutura

```
SmartHome/
├── docker-compose.yml          # base, funciona sem GPU
├── docker-compose.nvidia.yml   # extra para NVIDIA
├── docker-compose.amd.yml      # extra para AMD (ROCm)
├── .env.example                # copiar para .env (o script 00 faz isto)
├── homeassistant/
│   ├── configuration.yaml      # inclui o bloco http: (proxy Tailscale)
│   └── automations.yaml, scenes.yaml, scripts.yaml
├── scripts/                    # instalação, backup, atualização, verificação
└── docs/guia-original.txt      # o guia completo
```

A placa escolhida fica guardada no `.env` (`GPU=` e `COMPOSE_FILE=`), por isso `docker compose up -d` usa sempre os ficheiros certos.

## Instalação (no PC Ubuntu)

Copiar esta pasta para o PC (por exemplo para `~/casa`) e correr os scripts **por ordem**. O primeiro é comum:

```bash
cd ~/casa
bash scripts/00-escolher-gpu.sh        # pergunta: NVIDIA, AMD ou nenhuma (ou: ... amd)
```

**NVIDIA**

```bash
bash scripts/01-drivers-nvidia.sh      # depois: sudo reboot  e confirmar com nvidia-smi
bash scripts/02-docker.sh              # depois: logout e login
bash scripts/03-nvidia-container-toolkit.sh
bash scripts/04-arrancar.sh
bash scripts/verificar.sh --gpu-teste
```

**AMD**

```bash
bash scripts/01-drivers-amd.sh         # verifica; se faltar o driver, diz como obter o URL do ROCm
bash scripts/01-drivers-amd.sh URL     # instala o ROCm v7 (depois: sudo reboot)
bash scripts/02-docker.sh              # depois: logout e login
bash scripts/04-arrancar.sh            # o 03 não é preciso
bash scripts/verificar.sh --gpu-teste
```

**Sem GPU**

```bash
bash scripts/02-docker.sh              # depois: logout e login
bash scripts/04-arrancar.sh
```

Antes do passo 04, no router: reservar um IP fixo para o PC (e ligar por cabo, se possível).

### Notas para AMD

- O Ollama só aceita certas placas no ROCm (Radeon RX 9000, 7000 e 6000, várias Radeon PRO e algumas Instinct). Vê a lista atual em <https://docs.ollama.com/gpu>.
- Se a tua placa não estiver na lista, descomenta `HSA_OVERRIDE_GFX_VERSION` no `.env` com o valor de uma placa parecida (por exemplo `10.3.0` para RX 6600/6700) e corre `docker compose up -d`.
- O `verificar.sh --gpu-teste` diz se o Ollama está mesmo a usar a GPU. Se estiver no CPU, a IA funciona mas é bem mais lenta, e convém usar um modelo mais pequeno (`OLLAMA_MODEL` no `.env`).

## Configurar o Home Assistant (na interface)

Abrir `http://IP-DO-PC:8123`, fazer a configuração inicial (recusar partilha de estatísticas) e, em
**Definições → Dispositivos e serviços → Adicionar integração**:

| Integração | Host | Porta | Quando |
|---|---|---|---|
| Wyoming Protocol (Whisper) | 127.0.0.1 | 10300 | sempre (GPU em NVIDIA, CPU nos outros casos) |
| Wyoming Protocol (Whisper CPU) | 127.0.0.1 | 10301 | só com NVIDIA (reserva) |
| Wyoming Protocol (Piper) | 127.0.0.1 | 10200 | sempre |
| Ollama | http://127.0.0.1:11434 | — | sempre |

Em **Definições → Assistentes de voz**:

- **Casa IA**: voz para texto = faster-whisper (porta 10300); agente = Ollama com controlo do Home Assistant ativado; texto para voz = Piper (voz portuguesa); ativar prioridade ao processamento local de comandos.
- **Casa Simples** (plano B, só com NVIDIA): voz para texto = faster-whisper (CPU, porta 10301); agente = Home Assistant (local, sem IA); texto para voz = Piper.
- Em **Expor**, escolher os dispositivos que a IA pode controlar.

## HTTPS e acesso remoto (Tailscale)

O browser só deixa usar o microfone em HTTPS. Na consola web do Tailscale → DNS, ativar **MagicDNS** e **HTTPS Certificates**, depois:

```bash
bash scripts/05-tailscale.sh
```

O endereço fica `https://nome-do-pc.xxxx.ts.net`. O bloco `http:` com `trusted_proxies` já está em `homeassistant/configuration.yaml`.

## Dia a dia

| O quê | Comando |
|---|---|
| Atualizar tudo | `bash scripts/atualizar.sh` |
| Ver logs | `docker compose logs -f` |
| Verificar estado | `bash scripts/verificar.sh` |
| Confirmar que a IA usa a GPU | `bash scripts/verificar.sh --gpu-teste` |
| Desligar/ligar o Ollama | `bash scripts/ollama.sh parar` / `iniciar` |
| Mudar de placa | `bash scripts/00-escolher-gpu.sh amd` e depois `docker compose up -d` |

## Backups

1. No Home Assistant: **Definições → Sistema → Backups** → backups automáticos diários (guardar os últimos 7). Ficam em `homeassistant/backups`.
2. Cópia para disco externo: editar `BACKUP_DESTINO` no `.env` (ver o nome do disco com `ls /media/$USER`), testar `bash scripts/backup-casa.sh` e agendar:

```bash
crontab -e
# todos os dias às 4h (trocar pelo caminho real da pasta):
0 4 * * * /bin/bash /home/O-TEU-UTILIZADOR/casa/scripts/backup-casa.sh
```

Restaurar num PC novo: repetir os passos de instalação, copiar a pasta, `bash scripts/04-arrancar.sh` e, na configuração inicial do Home Assistant, escolher **Restaurar a partir de backup**.

## Plano B: se a placa gráfica avariar

- Usar um CPU com gráfica integrada (Intel sem **F** no nome; AMD Ryzen 7000/9000, ou modelos **G** nos mais antigos) e deixar a gráfica integrada ativa na BIOS.
- Com NVIDIA, sem GPU o Whisper (GPU) e o Ollama não arrancam; o resto continua a funcionar. Mudar o satélite para o assistente **Casa Simples**. Para arrancar tudo no CPU: `bash scripts/00-escolher-gpu.sh none` e `docker compose up -d`.

## Notas

- O Ollama não tem autenticação: só pôr `OLLAMA_BIND=0.0.0.0` no `.env` se for mesmo preciso.
- O `medium-int8` é um bom equilíbrio no Whisper com GPU NVIDIA; para mais precisão experimentar `turbo` ou `large-v3`, conforme os nomes suportados pela imagem. No CPU, `small-int8` é o ponto de partida.
- HACS e satélites de voz no Mac (secções 13 e 16 do guia) são passos manuais, descritos em `docs/guia-original.txt`.
