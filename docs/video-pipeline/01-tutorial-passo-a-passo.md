# Tutorial passo a passo — Pipeline local de vídeos públicos de abordagens policiais

## 1. Objetivo deste tutorial

Este tutorial descreve como montar uma primeira versão funcional da pipeline local para transformar vídeos públicos e oficiais em conteúdo comentado, revisado, censurado e pronto para publicação.

A abordagem proposta é incremental. Primeiro, cria-se uma pipeline manual assistida por automação. Depois, cada etapa passa a ser integrada por Prefect, UI de revisão e scripts reutilizáveis.

## 2. Resultado esperado

Ao final da implementação inicial, o fluxo deve permitir:

1. Registrar uma fonte oficial.
2. Baixar ou importar um vídeo autorizado.
3. Gerar proxy leve para revisão.
4. Extrair áudio.
5. Transcrever com WhisperX.
6. Detectar PII textual com Presidio.
7. Detectar rostos, placas e elementos sensíveis no vídeo.
8. Revisar marcações em interface própria.
9. Aplicar cortes, mute, blur e legendas.
10. Gerar narração.
11. Renderizar vídeo final.
12. Preparar metadados para upload.

## 3. Pré-requisitos

### 3.1 Sistema operacional

Recomendação principal:

- Ubuntu Server/Desktop LTS, Debian, EndeavourOS/Arch ou Windows 11 com WSL2.

Para a primeira versão, Linux tende a ser mais simples para scripts, FFmpeg, CUDA, Python e automações.

### 3.2 Pacotes base

Instale:

```bash
sudo apt update
sudo apt install -y git curl wget ffmpeg python3 python3-venv python3-pip nodejs npm postgresql
```

Em Arch/EndeavourOS, use equivalentes:

```bash
sudo pacman -Syu git curl wget ffmpeg python python-pip nodejs npm postgresql
```

### 3.3 Driver NVIDIA e CUDA

Instale driver NVIDIA atualizado. Depois valide:

```bash
nvidia-smi
```

Você deve ver a RTX 3080 e uso de VRAM.

Para WhisperX com GPU, instale CUDA compatível com a versão exigida pelo pacote e pelo PyTorch. Em caso de conflito, prefira seguir a matriz oficial do PyTorch para a versão CUDA suportada.

### 3.4 Estrutura do projeto

Crie uma pasta principal:

```bash
mkdir -p ~/police-video-pipeline
cd ~/police-video-pipeline
```

Estrutura recomendada:

```bash
mkdir -p data/{sources,raw,proxy,audio,transcripts,pii,masks,reviewed,output}
mkdir -p flows scripts ui config logs docs
```

## 4. Ambiente Python

Crie ambiente virtual:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip wheel setuptools
```

Instale dependências iniciais:

```bash
pip install prefect yt-dlp whisperx presidio-analyzer presidio-anonymizer spacy fastapi uvicorn pydantic python-dotenv
```

Instale modelo spaCy para inglês:

```bash
python -m spacy download en_core_web_lg
```

Caso o modelo grande seja pesado demais para testes, use:

```bash
python -m spacy download en_core_web_sm
```

## 5. Instalação do Node-RED

Instale Node-RED globalmente:

```bash
sudo npm install -g node-red
```

Inicie:

```bash
node-red
```

Acesse:

```text
http://localhost:1880
```

Uso recomendado no projeto:

- Acionar fluxos manualmente.
- Exibir botões simples de aprovação.
- Receber webhooks.
- Chamar scripts locais.
- Integrar notificações.

Não use Snap para esse projeto, porque os fluxos precisam acessar arquivos, Git, FFmpeg, Python, GPU e comandos externos.

## 6. Configuração do Prefect

Inicie servidor local:

```bash
prefect server start
```

Em outro terminal:

```bash
prefect profile create local-video-pipeline
prefect profile use local-video-pipeline
```

Se a URL da API aparecer no terminal do servidor, configure:

```bash
prefect config set PREFECT_API_URL=http://127.0.0.1:4200/api
```

Para produção, configure PostgreSQL. Para MVP, SQLite é suficiente.

## 7. Registro de fonte

Crie um arquivo de fonte para cada vídeo:

```json
{
  "source_id": "lapd-2026-001",
  "source_url": "https://...",
  "agency": "Los Angeles Police Department",
  "source_type": "official_youtube",
  "event_date": "2026-01-01",
  "download_date": "2026-04-25",
  "license_notes": "Public official release; verify terms before reuse.",
  "editorial_notes": "Use only low-violence excerpts. Blur faces and plates.",
  "status": "pending_ingestion"
}
```

Salve em:

```text
data/sources/lapd-2026-001.json
```

Campos mínimos:

| Campo | Uso |
|---|---|
| `source_id` | ID interno único |
| `source_url` | URL original |
| `agency` | Agência/publicador |
| `source_type` | YouTube oficial, DVIDS, portal público, FOIA |
| `license_notes` | Observações legais |
| `editorial_notes` | Critérios de edição |
| `status` | Estado na pipeline |

## 8. Download/importação do vídeo

### 8.1 Download via yt-dlp

Use somente quando a fonte permitir download/reuso.

```bash
yt-dlp \
  -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" \
  --merge-output-format mp4 \
  --write-info-json \
  --write-thumbnail \
  --write-auto-sub \
  --sub-lang en \
  -o "data/raw/%(id)s/%(title).120s.%(ext)s" \
  "URL_DO_VIDEO"
```

### 8.2 Importação manual

Se o vídeo foi obtido por portal público ou pedido formal:

```bash
mkdir -p data/raw/lapd-2026-001
cp ~/Downloads/video.mp4 data/raw/lapd-2026-001/original.mp4
```

### 8.3 Registro de hash

Gere hash para rastreabilidade:

```bash
sha256sum data/raw/lapd-2026-001/original.mp4 > data/raw/lapd-2026-001/original.sha256
```

## 9. Geração de proxy para revisão

Vídeos longos em 1080p/4K são pesados. Gere proxy:

```bash
ffmpeg -y \
  -i data/raw/lapd-2026-001/original.mp4 \
  -vf "scale=1280:-2" \
  -c:v h264_nvenc -preset fast -b:v 2500k \
  -c:a aac -b:a 128k \
  data/proxy/lapd-2026-001_proxy.mp4
```

Se NVENC falhar, use CPU:

```bash
ffmpeg -y \
  -i data/raw/lapd-2026-001/original.mp4 \
  -vf "scale=1280:-2" \
  -c:v libx264 -preset veryfast -crf 28 \
  -c:a aac -b:a 128k \
  data/proxy/lapd-2026-001_proxy.mp4
```

## 10. Extração de áudio

```bash
ffmpeg -y \
  -i data/raw/lapd-2026-001/original.mp4 \
  -vn -ac 1 -ar 16000 \
  data/audio/lapd-2026-001.wav
```

Esse formato é adequado para STT.

## 11. Transcrição com WhisperX

### 11.1 Execução GPU

```bash
whisperx data/audio/lapd-2026-001.wav \
  --model large-v2 \
  --language en \
  --device cuda \
  --compute_type float16 \
  --output_dir data/transcripts/lapd-2026-001 \
  --highlight_words True
```

### 11.2 Execução com diarização

```bash
whisperx data/audio/lapd-2026-001.wav \
  --model large-v2 \
  --language en \
  --device cuda \
  --compute_type float16 \
  --diarize \
  --hf_token "$HF_TOKEN" \
  --output_dir data/transcripts/lapd-2026-001 \
  --highlight_words True
```

### 11.3 Execução CPU emergencial

```bash
whisperx data/audio/lapd-2026-001.wav \
  --model medium \
  --language en \
  --device cpu \
  --compute_type int8 \
  --output_dir data/transcripts/lapd-2026-001
```

## 12. Detecção textual de PII com Presidio

Crie `scripts/detect_pii_text.py`:

```python
import json
from pathlib import Path
from presidio_analyzer import AnalyzerEngine

TRANSCRIPT = Path("data/transcripts/lapd-2026-001/lapd-2026-001.json")
OUTPUT = Path("data/pii/lapd-2026-001_text_pii.json")
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

analyzer = AnalyzerEngine()

payload = json.loads(TRANSCRIPT.read_text(encoding="utf-8"))
segments = payload.get("segments", [])

findings = []
for segment in segments:
    text = segment.get("text", "")
    results = analyzer.analyze(text=text, language="en")
    for result in results:
        findings.append({
            "segment_start": segment.get("start"),
            "segment_end": segment.get("end"),
            "entity_type": result.entity_type,
            "score": result.score,
            "text_start": result.start,
            "text_end": result.end,
            "excerpt": text[result.start:result.end],
        })

OUTPUT.write_text(json.dumps(findings, indent=2), encoding="utf-8")
print(f"Saved {len(findings)} findings to {OUTPUT}")
```

Execute:

```bash
python scripts/detect_pii_text.py
```

## 13. Detecção visual de rostos e placas

### 13.1 Opção com video-privacy-blur

Clone e instale:

```bash
git clone https://github.com/MengWoods/video-privacy-blur.git tools/video-privacy-blur
cd tools/video-privacy-blur
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
```

Baixe os pesos exigidos no diretório `models/`:

- Modelo de face YOLO.
- Modelo de placa.

Rode:

```bash
privacy-blur \
  --input ../../data/raw/lapd-2026-001/original.mp4 \
  --output ../../data/reviewed/lapd-2026-001_blurred_preview.mp4 \
  --face-detector yolo \
  --face-yolo-weights models/yolov8n-face.pt \
  --plate-weights models/license_plate_detector.pt \
  --method pixelate \
  --device cuda
```

### 13.2 Ajustes úteis

Aumente precisão:

```bash
--imgsz 1280 --conf 0.25 --scale 1.45
```

Aumente velocidade:

```bash
--imgsz 640 --conf 0.35
```

Use pixelização forte:

```bash
--method pixelate --pixelate-blocks 8
```

## 14. Interface de revisão

A interface é a parte que deve ser priorizada cedo, porque ela reduz risco editorial. No MVP, ela pode ser simples.

### 14.1 Funcionalidades mínimas

A interface deve permitir:

1. Abrir proxy de vídeo.
2. Ver transcript sincronizado.
3. Ver achados de PII textual.
4. Ver preview com blur.
5. Marcar trecho como aprovado/reprovado.
6. Adicionar cortes manuais.
7. Adicionar timestamps para blur manual.
8. Exportar arquivo de decisão editorial.

### 14.2 Arquivo de decisões

Exemplo:

```json
{
  "source_id": "lapd-2026-001",
  "cuts": [
    { "start": 10.2, "end": 35.8, "reason": "intro long" }
  ],
  "mute": [
    { "start": 122.1, "end": 127.4, "reason": "personal address" }
  ],
  "blur_manual": [
    { "start": 220.0, "end": 230.0, "x": 100, "y": 200, "w": 300, "h": 120, "reason": "visible plate" }
  ],
  "age_safety": {
    "graphic_violence": false,
    "minors_visible": false,
    "sensitive_audio": true
  },
  "approved_for_render": false
}
```

### 14.3 Implementação inicial

Use FastAPI para backend:

```bash
pip install fastapi uvicorn
```

Rodar:

```bash
uvicorn ui.api:app --reload --port 8000
```

Front-end mínimo pode ser React, ou uma página HTML simples com `<video>` e lista de segmentos. O importante no início é exportar decisões corretamente.

## 15. Aplicação de cortes e mute

Cortes simples podem ser feitos por concatenação de segmentos aprovados.

Exemplo de geração de segmentos:

```bash
ffmpeg -y -i input.mp4 -ss 00:00:00 -to 00:05:00 -c copy segment_001.mp4
ffmpeg -y -i input.mp4 -ss 00:05:30 -to 00:20:00 -c copy segment_002.mp4
```

Crie `concat.txt`:

```text
file 'segment_001.mp4'
file 'segment_002.mp4'
```

Concatene:

```bash
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy cut_output.mp4
```

Para mute de trecho sensível, use filtros de volume com intervalos.

## 16. Narração

### 16.1 Roteiro

Estrutura recomendada:

1. Contexto do caso.
2. Fonte e data.
3. O que será analisado.
4. Trechos importantes.
5. Observações técnicas.
6. Encerramento.

Evite linguagem acusatória sem base documental. Use termos como:

- “segundo a gravação publicada”.
- “de acordo com o briefing oficial”.
- “o vídeo aparenta mostrar”.
- “a conclusão depende da investigação”.

### 16.2 TTS

Gere trechos curtos. Isso facilita correção.

Padrão de arquivos:

```text
data/audio/narration/lapd-2026-001/001_intro.wav
data/audio/narration/lapd-2026-001/002_context.wav
data/audio/narration/lapd-2026-001/003_analysis.wav
```

## 17. Montagem final

### 17.1 Mixagem simples

```bash
ffmpeg -y \
  -i data/reviewed/lapd-2026-001_blurred_preview.mp4 \
  -i data/audio/narration/lapd-2026-001/full_narration.wav \
  -filter_complex "[0:a]volume=0.75[a0];[1:a]volume=1.0[a1];[a0][a1]amix=inputs=2:duration=first[aout]" \
  -map 0:v -map "[aout]" \
  -c:v h264_nvenc -preset slow -b:v 8000k \
  -c:a aac -b:a 192k \
  data/output/lapd-2026-001_final.mp4
```

### 17.2 Inserção de legendas

```bash
ffmpeg -y \
  -i data/output/lapd-2026-001_final.mp4 \
  -vf "subtitles=data/transcripts/lapd-2026-001/lapd-2026-001.srt" \
  -c:v h264_nvenc -preset slow -b:v 8000k \
  -c:a copy \
  data/output/lapd-2026-001_final_subtitled.mp4
```

## 18. Checklist de revisão final

Antes de publicar:

- [ ] Fonte registrada.
- [ ] Direitos de uso avaliados.
- [ ] Descrição inclui fonte.
- [ ] Transcript revisado.
- [ ] PII textual removida ou censurada.
- [ ] Rostos e placas revisados.
- [ ] Minors e vítimas protegidos.
- [ ] Violência gráfica removida ou censurada.
- [ ] Linguagem ofensiva tratada, se necessário.
- [ ] Narração adiciona contexto real.
- [ ] Miniatura não sensacionalista.
- [ ] Legendas revisadas.
- [ ] Metadados prontos.
- [ ] Aprovação humana registrada.

## 19. Integração com Prefect

Depois de validar tudo manualmente, automatize.

Fluxo sugerido:

```python
from prefect import flow, task

@task
def ingest_source(source_id: str):
    ...

@task
def generate_proxy(video_path: str):
    ...

@task
def extract_audio(video_path: str):
    ...

@task
def run_transcription(audio_path: str):
    ...

@task
def detect_text_pii(transcript_path: str):
    ...

@task
def detect_visual_pii(video_path: str):
    ...

@task
def wait_for_review(source_id: str):
    ...

@task
def render_final(source_id: str):
    ...

@flow
def video_pipeline(source_id: str):
    video = ingest_source(source_id)
    proxy = generate_proxy(video)
    audio = extract_audio(video)
    transcript = run_transcription(audio)
    text_pii = detect_text_pii(transcript)
    visual_pii = detect_visual_pii(video)
    wait_for_review(source_id)
    render_final(source_id)
```

## 20. Próximos passos práticos

1. Implementar estrutura de pastas.
2. Criar scripts mínimos para cada etapa.
3. Testar com um vídeo curto e oficial.
4. Criar JSON de fonte e JSON de decisões.
5. Criar UI simples de revisão.
6. Integrar com Prefect.
7. Só depois automatizar upload.
