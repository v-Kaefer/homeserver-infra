# Planejamento — Pipeline local para produção de vídeos públicos de abordagens policiais

## 1. Visão geral

Este planejamento organiza a implementação da pipeline em fases, com entregas, critérios de aceite, riscos e backlog técnico. A proposta é começar com uma arquitetura simples e revisável, evitando automatizar publicação antes de consolidar a revisão humana.

A ideia principal é construir primeiro uma base operacional confiável: ingestão, transcrição, detecção de PII, blur, revisão e renderização. Depois, a pipeline pode evoluir para uma interface centralizada, agendamento, automações com Prefect e upload assistido.

## 2. Objetivos do projeto

### 2.1 Objetivo principal

Criar uma pipeline local que produza vídeos educativos e comentados a partir de gravações públicas e oficiais, com anonimização, contextualização e controle editorial.

### 2.2 Objetivos secundários

1. Reduzir o tempo de preparação de vídeos longos.
2. Padronizar decisões de censura e privacidade.
3. Registrar origem e direitos de uso de cada vídeo.
4. Criar base reutilizável para várias fontes oficiais.
5. Permitir revisão manual rápida antes da renderização.
6. Integrar automação sem perder controle editorial.

## 3. Fora do escopo inicial

Na primeira versão, não implementar:

- Upload 100% automático sem revisão.
- Publicação automática de vídeos.
- Uso de vídeos sem fonte oficial registrada.
- Treinamento próprio de modelos.
- Sistema complexo de multiusuário.
- Pipeline distribuída em múltiplas máquinas.
- Integração paga com serviços cloud.

Esses itens podem entrar em fases futuras, depois que a pipeline local estiver validada.

## 4. Princípios de arquitetura

### 4.1 Modularidade

Cada etapa deve ser isolada:

- Ingestão.
- Transcrição.
- Detecção textual.
- Detecção visual.
- Revisão.
- Edição.
- Narração.
- Renderização.
- Upload.

Isso permite trocar ferramentas sem reescrever o sistema inteiro.

### 4.2 Rastreabilidade

Todo vídeo deve ter:

- ID interno.
- Fonte original.
- Data de download/importação.
- Hash do arquivo bruto.
- Registro de decisões editoriais.
- Logs de processamento.
- Versão do output final.

### 4.3 Revisão obrigatória

A automação deve marcar, sugerir e acelerar. A aprovação final deve ser humana.

### 4.4 Baixo acoplamento

Scripts devem funcionar isoladamente. Prefect deve orquestrar, não conter toda a lógica.

### 4.5 Substituibilidade

WhisperX, Presidio, YOLO, Kokoro, FFmpeg e yt-dlp devem ser integrados por interfaces simples. Assim, novos modelos podem substituir componentes antigos.

## 5. Roadmap recomendado

## Fase 0 — Preparação do repositório

### Objetivo

Criar base documental e estrutura mínima para o projeto.

### Entregas

- [x] Sumário da arquitetura.
- [x] Tutorial passo a passo.
- [x] Planejamento de implementação.
- [ ] Estrutura inicial de pastas.
- [ ] `.gitignore` para arquivos de mídia, cache e modelos.
- [ ] README atualizado com links para os docs.

### Critérios de aceite

- Documentos revisados em Markdown.
- Estrutura clara para futuras implementações.
- Nenhum arquivo pesado versionado.

## Fase 1 — Pipeline manual validada

### Objetivo

Executar o processo completo uma vez, mesmo que com comandos manuais.

### Entregas

- Script de ingestão/importação.
- Script de geração de proxy.
- Script de extração de áudio.
- Execução WhisperX funcional.
- Execução Presidio funcional.
- Execução de blur inicial funcional.
- Renderização final simples.

### Critérios de aceite

- Um vídeo curto oficial processado do início ao fim.
- Transcript gerado.
- Achados de PII salvos em JSON.
- Preview com blur gerado.
- Output final gerado.
- Nenhuma etapa depende de edição manual desorganizada.

### Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| CUDA incompatível | Alto | Fixar versões de PyTorch/WhisperX |
| Vídeo longo demais | Médio | Testar com clipes de 5 a 10 minutos |
| YOLO falha em blur | Alto | Revisão manual e detector adicional |
| Presidio perde PII | Alto | Regex customizadas e revisão humana |

## Fase 2 — Interface de revisão mínima

### Objetivo

Centralizar revisão de transcript, PII, blur e decisões editoriais.

### Entregas

- Backend FastAPI simples.
- Página de revisão com player de vídeo.
- Lista de segmentos do transcript.
- Lista de achados PII.
- Formulário para cortes, mute e blur manual.
- Exportação de `review_decisions.json`.

### Critérios de aceite

- Operador consegue revisar um vídeo sem editar arquivos manualmente.
- Decisões são salvas em JSON padronizado.
- Pipeline consegue consumir as decisões.

### Priorização

Esta fase deve ser antecipada. A interface reduz o risco do mês 4 porque transforma triagem em processo controlado desde o início.

## Fase 3 — Orquestração com Prefect

### Objetivo

Transformar comandos manuais em tarefas rastreáveis.

### Entregas

- Flow `ingest_source`.
- Flow `transcribe_video`.
- Flow `detect_pii`.
- Flow `render_review_preview`.
- Flow `render_final`.
- Logs por `source_id`.
- Estado de cada vídeo.

### Critérios de aceite

- Pipeline pode ser disparada por `source_id`.
- Falhas aparecem no painel do Prefect.
- Tarefas podem ser reexecutadas sem refazer tudo.
- Outputs intermediários são reaproveitados.

## Fase 4 — Templates editoriais e narração

### Objetivo

Padronizar roteiro, narração, legendas e identidade do canal.

### Entregas

- Template de roteiro.
- Template de descrição do YouTube.
- Template de disclaimer.
- Template de capítulos.
- Script de geração TTS.
- Mixagem de áudio com ducking.
- Presets de FFmpeg para render final.

### Critérios de aceite

- Roteiro gerado em Markdown.
- Narração gerada por blocos.
- Vídeo final inclui contexto e não apenas republicação.
- Output mantém qualidade visual e áudio claro.

## Fase 5 — Upload assistido

### Objetivo

Preparar upload semi-automatizado, mantendo aprovação humana.

### Entregas

- Geração de título.
- Geração de descrição.
- Geração de tags.
- Geração de capítulos.
- Preparação de thumbnail.
- Script de upload opcional via YouTube Data API.
- Checklist de aprovação final.

### Critérios de aceite

- Upload não ocorre sem `approved_for_upload=true`.
- Metadados incluem fonte e contexto.
- Legendas são anexadas.
- Logs registram data e versão do vídeo.

## Fase 6 — Escala e refinamento

### Objetivo

Aumentar cadência e reduzir esforço manual.

### Entregas

- Monitoramento de novas fontes.
- Fila de processamento.
- Dashboard de status.
- Métricas de tempo por etapa.
- Testes com modelos STT alternativos.
- Testes com detectores visuais alternativos.

### Critérios de aceite

- Suporta 1 vídeo/semana com conforto.
- Suporta 3 vídeos/semana com revisão planejada.
- Tempo de retrabalho reduz progressivamente.

## 6. Backlog técnico

### 6.1 Ingestão

- [ ] Criar schema JSON para fontes.
- [ ] Criar script `register_source.py`.
- [ ] Criar script `download_source.py`.
- [ ] Validar URLs permitidas.
- [ ] Gerar hash SHA256 do vídeo bruto.
- [ ] Salvar metadados de yt-dlp.

### 6.2 Transcrição

- [ ] Criar wrapper Python para WhisperX.
- [ ] Configurar modelos por tamanho.
- [ ] Exportar JSON normalizado.
- [ ] Exportar SRT revisável.
- [ ] Implementar diarização opcional.
- [ ] Criar fallback CPU.

### 6.3 PII textual

- [ ] Integrar Presidio.
- [ ] Criar regex customizadas para placas, endereços e telefones.
- [ ] Mapear entidades para timestamps.
- [ ] Exportar achados para UI.
- [ ] Criar confiança mínima por tipo de entidade.

### 6.4 PII visual

- [ ] Integrar detector de rosto.
- [ ] Integrar detector de placa.
- [ ] Salvar bounding boxes por frame ou intervalo.
- [ ] Criar preview com blur.
- [ ] Permitir blur manual.
- [ ] Exportar relatório de frames com baixa confiança.

### 6.5 Revisão

- [ ] Criar player com timeline.
- [ ] Exibir transcript sincronizado.
- [ ] Permitir edição de texto.
- [ ] Permitir marcação de cortes.
- [ ] Permitir marcação de mute.
- [ ] Permitir marcação de blur manual.
- [ ] Salvar `review_decisions.json`.

### 6.6 Renderização

- [ ] Criar parser de decisões.
- [ ] Gerar filtros FFmpeg automaticamente.
- [ ] Aplicar cortes.
- [ ] Aplicar mute/bleep.
- [ ] Aplicar blur.
- [ ] Inserir legendas.
- [ ] Mixar narração.
- [ ] Gerar output final.

### 6.7 Narração

- [ ] Definir modelo TTS padrão.
- [ ] Criar script de geração por blocos.
- [ ] Normalizar loudness.
- [ ] Adicionar ducking.
- [ ] Gerar arquivos por segmento.

### 6.8 Upload

- [ ] Criar template de título.
- [ ] Criar template de descrição.
- [ ] Criar template de tags.
- [ ] Criar checklist final.
- [ ] Integrar YouTube Data API.
- [ ] Evitar upload se não houver aprovação.

## 7. Estrutura de arquivos proposta

```text
homeserver-infra/
├─ docs/
│  └─ video-pipeline/
│     ├─ 00-sumario.md
│     ├─ 01-tutorial-passo-a-passo.md
│     └─ 02-planejamento.md
├─ video-pipeline/
│  ├─ config/
│  ├─ flows/
│  ├─ scripts/
│  ├─ ui/
│  ├─ schemas/
│  └─ templates/
└─ README.md
```

Arquivos de mídia, modelos e outputs não devem entrar no Git:

```text
data/
models/
*.mp4
*.mkv
*.mov
*.wav
*.mp3
*.srt
*.vtt
*.pt
*.onnx
*.log
```

## 8. Critérios de qualidade

### 8.1 Código

- Scripts idempotentes.
- Erros claros.
- Logs por `source_id`.
- Configuração por `.env`.
- Caminhos relativos ao projeto.
- Sem arquivos pesados no repositório.

### 8.2 Documentação

- Cada etapa deve ter comando reproduzível.
- Cada script deve ter exemplos.
- Cada arquivo JSON deve ter schema documentado.
- Cada decisão editorial deve ser rastreável.

### 8.3 Editorial

- Nada de sensacionalismo.
- Contexto antes de julgamento.
- Preservação de privacidade.
- Baixa exposição a violência explícita.
- Fonte sempre citada.

## 9. Riscos principais

| Risco | Severidade | Probabilidade | Mitigação |
|---|---|---|---|
| Uso indevido de material protegido | Alta | Média | Fonte oficial, registro, fair use transformativo |
| PII não censurado | Alta | Média | Presidio + YOLO + revisão manual |
| Restrição de idade no YouTube | Média | Média | Cortes e blur em violência explícita |
| Claim de copyright | Média | Alta | Fonte, contexto, análise, documentação de uso |
| Falha de CUDA/WhisperX | Média | Média | Fixar versões, fallback CPU |
| Pipeline complexa cedo demais | Média | Alta | Começar manual e automatizar depois |
| Upload automático indevido | Alta | Baixa | Gate obrigatório de aprovação |

## 10. Métricas de sucesso

### 10.1 Técnicas

- Tempo de transcrição por hora de vídeo.
- Tempo de detecção visual por hora de vídeo.
- Número de intervenções manuais.
- Taxa de falhas por etapa.
- Tempo total até render final.

### 10.2 Editoriais

- Percentual de vídeos sem retrabalho após revisão final.
- Número de PII encontrados manualmente após automação.
- Número de cenas removidas por violência explícita.
- Retenção média no YouTube.
- Comentários sobre clareza/contexto.

### 10.3 Operacionais

- Vídeos produzidos por semana.
- Tempo médio por vídeo.
- Custo operacional.
- Espaço em disco consumido.
- Taxa de reaproveitamento de templates.

## 11. Plano de implementação por mês

### Mês 1 — Base e primeiro vídeo curto

Foco:

- Estrutura de projeto.
- Dependências.
- Download/importação.
- Proxy.
- Transcrição.
- Primeiro teste de PII.

Resultado esperado:

- Um clipe curto processado com transcript e preview.

### Mês 2 — Interface de revisão mínima

Foco:

- Player.
- Transcript.
- Achados PII.
- Decisões JSON.

Resultado esperado:

- Revisão deixa de depender de edição manual em arquivos soltos.

### Mês 3 — Blur e renderização confiável

Foco:

- Detecção visual.
- Preview com blur.
- Cortes e mute.
- Render final.

Resultado esperado:

- Um vídeo completo produzido localmente.

### Mês 4 — Orquestração Prefect

Foco:

- Encapsular tarefas.
- Persistir estado.
- Reexecutar etapas.
- Logs e dashboard.

Resultado esperado:

- Pipeline executada por `source_id`.

### Mês 5 — Narração e identidade editorial

Foco:

- TTS.
- Roteiro.
- Template de descrição.
- Template de capítulos.
- Miniatura.

Resultado esperado:

- Vídeo transformativo e padronizado.

### Mês 6 — Upload assistido e rotina semanal

Foco:

- Checklist final.
- Metadados.
- Upload semi-automatizado.
- Rotina de publicação.

Resultado esperado:

- Um vídeo por semana com processo estável.

## 12. Decisão sobre a interface centralizada

A interface deve ser priorizada antes da automação completa. Ela não precisa ser bonita no começo, mas precisa ser funcional.

Motivo:

- O maior risco não é baixar ou transcrever vídeo.
- O maior risco é publicar algo com PII, violência explícita, contexto errado ou edição problemática.

Portanto, a UI deve existir cedo para funcionar como centro de triagem.

## 13. Próxima ação recomendada

Implementar os seguintes itens na próxima branch técnica:

1. `.gitignore` para arquivos pesados.
2. Estrutura `video-pipeline/`.
3. Schemas JSON de fonte e decisões.
4. Script de geração de proxy.
5. Script de extração de áudio.
6. Wrapper inicial de WhisperX.
7. README de execução local.

Esta branch atual deve permanecer documental e servir como referência de implementação.
