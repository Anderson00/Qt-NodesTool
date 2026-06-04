# Análise Estratégica — Próximas Implementações do Valkyrie

> Análise gerada com base na inspeção de 13 arquivos críticos do projeto.
> Arquivos inspecionados: `viewportwindow.h`, `behaviours.h`, `connections.h`, `behaviourregistry.h`,
> `nodeundocommands.h`, `desktopmanager.h`, `workspacemanager.h`, `pythonengine.h`,
> `variablemanager.h`, `ViewPortWindow.qml`, `ViewComponentRectV2.qml`,
> `CommandPalette.qml`, `GroupFrame.qml`

---

## Diagnóstico: O que já existe (e é impressionante)

O Valkyrie já supera muitos editores comerciais lançados nos últimos 5 anos:

| Feature | Status |
|---|---|
| Tipagem semântica de pinos (11 tipos + FlowType) | ✅ |
| Exec pins separados de data pins (Blueprint-style) | ✅ |
| Undo/redo completo com comandos mergeáveis | ✅ |
| Virtual Desktops + Ctrl+Tab overview | ✅ (Unreal não tem isso) |
| Command Palette Ctrl+P | ✅ |
| Group Frames visuais | ✅ |
| Python 3.11 embarcado em thread dedicada | ✅ |
| 75+ nós em 18 categorias | ✅ |
| i18n completo (en/pt_BR/es) | ✅ |

**Ponto de atenção:** `ViewPortWindow.qml` tem ~193KB / 4000+ linhas — está chegando no limite de manutenibilidade.

---

## 1. 🟢 Melhorias Imediatas (Quick Wins)

### 1.1 Reroute / Knot Nodes
**Impacto: muito alto | Esforço: 3–5 dias**

Nó "invisível" 1-in/1-out que redireciona fios. Blueprint, Blender e Houdini todos têm. Duplo-clique num fio → cria knot. Implementar como `RerouteNode` Behaviour com QML minimalista (círculo de 14px). O tipo do pino herda do upstream automaticamente.

### 1.2 Sticky Notes independentes
**Impacto: alto | Esforço: 2–3 dias**

`GroupFrame.qml` já existe com header editável — estender para `StickyNote.qml` (post-it redimensionável com texto rico). Adicionar `AddStickyCommand` no sistema de undo.

### 1.3 Tooltip de valor ao vivo na conexão
**Impacto: alto (debug UX) | Esforço: 2 dias**

Hover num fio → mostra o `QVariant` atual sendo trafegado. Cachear o último valor em `Connections::addConnection` e expor via `Q_INVOKABLE getLastValue()`. É o **equivalente ao value watch do TouchDesigner** e muda completamente a experiência de debug.

### 1.4 Find Nodes (Ctrl+F) no canvas
**Impacto: alto | Esforço: 1–2 dias**

`CommandPalette` já tem a infra. Adicionar grupo "Go to node" que lista nós por título e ao selecionar faz pan/zoom + highlight pulsante.

### 1.5 Hot Reload Python
**Impacto: alto (dev workflow) | Esforço: 3 dias**

`PythonBehaviour` já tem `loadFromFile`. Adicionar `QFileSystemWatcher` no path → ao detectar mudança externa, recarrega automaticamente. Edita no VS Code/PyCharm, vê resultado no Valkyrie em tempo real.

### 1.6 Wildcard PinType
**Impacto: alto | Esforço: 3 dias**

Adicionar `WildcardType` ao enum — resolve para o tipo concreto quando o primeiro fio conecta. Essencial para `Hub`, `Gate`, `BufferAccumulator`.

### 1.7 Auto-align / Distribute multi-select
**Impacto: médio | Esforço: 1–2 dias**

Multi-select → botões: alinhar topo/centro/base/esquerda/direita, distribuir H/V. Um `QUndoCommand` agrupado.

---

## 2. 🟡 Features de Edição de Nós (Essenciais)

### 2.1 ⭐ Subgraph / Composite / Macro
**Impacto: TRANSFORMADOR | Esforço: 1–2 meses**

Esta é a **feature mais importante que falta**. Sem ela, não dá pra construir grafos "grandes" de produção.

- Selecionar N nós → "Collapse to subgraph" → vira 1 nó com pins derivados
- Duplo-clique → entra no subgraph com **breadcrumb** (já tem `BreadcrumbBar.qml`!)
- Salvar como `.valkyrie-asset` reutilizável
- Referências: Blueprint Macros, TouchDesigner COMPs, Houdini HDA

**Arquitetura:** `SubgraphBehaviour` contendo um `QHash<QString, Behaviours*>` interno (mesma estrutura do `ViewPortWindow`). Pinos de I/O derivados de `ProxyInput`/`ProxyOutput` nodes internos.

### 2.2 Minimap / Navigator
**Impacto: alto | Esforço: 1 semana**

Painel 200×150px canto inferior-direito com retângulo do viewport atual. Arrastar = pan rápido. Crítico em grafos com 100+ nós.

### 2.3 Variadic Pins (inputs dinâmicos)
**Impacto: alto | Esforço: 1 semana**

Nós com pinos `+` sob demanda. `FlowMerge` já faz com 3 fixos — generalizar.

### 2.4 Bookmarks no canvas
**Impacto: médio | Esforço: 2 dias**

Marcar regiões com nome. Lista lateral com 1-click pan. Reutiliza lógica do `DesktopManager`.

---

## 3. 🔴 Features de Poder (Diferenciadores de Mercado)

### 3.1 ⭐ Visual Debugger — Breakpoints + Step-through
**Impacto: ENORME | Esforço: 3–4 semanas**

O app **se chama Debugger.exe**. Essa feature confirma a identidade do produto:

- Direito-clique em exec pin → "Toggle Breakpoint" (círculo vermelho)
- Pausa o grafo no breakpoint → fios destacam o caminho ativo
- Valores aparecem como badges nos pinos
- Painel "Watch" lateral com últimos valores por nó
- F10/F11 step over / step into (subgraphs)
- LED verde com fade-out de 500ms indica última execução

### 3.2 Live Profiling Heatmap
**Impacto: alto | Esforço: 1 semana**

Instrumentar chamadas com `QElapsedTimer`. Toggle "heatmap" → nós coloridos verde→vermelho com tempo em ms. TouchDesigner faz isso e é decisivo para otimização.

### 3.3 CV Nodes (Computer Vision)
**Impacto: muito alto (nicho) | Esforço: 2–3 semanas**

`CameraViewer` já existe. Adicionar categoria `cv/`:
- `OpenCVCaptureNode` — `QVideoFrame → cv::Mat`
- `EdgeDetection`, `Blur`, `Threshold`, `OpticalFlow`
- `YOLODetectionNode` (ONNX runtime)
- `FaceDetectorNode`, `ArUcoDetector`

Com Python + numpy/scipy já embarcados, **seria um TouchDesigner grátis para computer vision** — nicho enorme e pouco coberto por concorrentes open-source.

### 3.4 OSC / MQTT / WebSocket Server
**Impacto: alto | Esforço: 1–2 semanas**

Existe `WebSocketClient`. Adicionar `WebSocketServer`, `OSCSender/Receiver`, `MQTTPublisher/Subscriber`. Posiciona o Valkyrie como hub central de pipelines IoT/media art.

### 3.5 Node Graph Diff visual
**Impacto: alto (equipes) | Esforço: 3–4 semanas**

Workspaces são JSON — diff visual entre versões: nós novos em verde, removidos em vermelho, modificados em laranja. Essencial para uso colaborativo via Git.

---

## 4. 🏗️ Infraestrutura

### 4.1 Refatorar ViewPortWindow.qml (URGENTE)
**Impacto: dev velocity | Esforço: 1–2 semanas**

193KB é insustentável. Extrair:
- `ViewPortInteraction.qml` — multi-select, rubber-band, drag
- `ViewPortClipboard.qml` — copy/paste/duplicate
- `ViewPortShortcuts.qml` — todos os `Shortcut`
- `ViewPortDesktopBinding.qml` — integração DesktopManager
- `ViewPortConnectionLayer.qml` — fios + radial menu

**Fazer ANTES de adicionar Subgraph** — senão fica inviável.

### 4.2 Serialização versionada + Migrations
**Esforço: 2–3 dias agora**

Adicionar `"format_version": 2` nos JSONs + `WorkspaceMigrator`. Sem isso, workspaces antigos quebram silenciosamente quando o schema mudar.

### 4.3 Sistema de Plugins (.dll dinâmico)
**Impacto: alto (ecossistema) | Esforço: 1 mês**

O enum `Type` já prevê `DLL`. Implementar `QPluginLoader` em `~/.valkyrie/plugins/`. Viabiliza ecossistema externo de nós da comunidade.

---

## 🗺️ Roadmap Recomendado (6 meses)

```
Fase 1 — Polimento (3–4 semanas)
  ✦ Reroute nodes
  ✦ Sticky notes
  ✦ Tooltip de valor ao vivo
  ✦ Find Nodes Ctrl+F
  ✦ Wildcard PinType
  ✦ Hot Reload Python

Fase 2 — Refatoração (2 semanas)
  ✦ Decompor ViewPortWindow.qml

Fase 3 — Game Changer (6–8 semanas)
  ✦ Subgraph / Composite ⭐
  ✦ Asset Library (depende de Subgraph)

Fase 4 — Identidade de Produto (6–8 semanas)
  ✦ Visual Debugger com breakpoints ⭐
  ✦ Live profiling heatmap
  ✦ Minimap

Fase 5 — Posicionamento de Mercado
  ✦ CV nodes (TouchDesigner grátis)
  ✦ Plugins .dll (ecossistema)
  ✦ MQTT/OSC (IoT/media art)
```

---

## Conclusão Estratégica

O Valkyrie já tem **mais features integradas que a maioria dos editores open-source**. As **3 alavancas de maior multiplicador estratégico** são:

1. **Subgraph** — sem isso não dá pra construir grafos de produção reais
2. **Visual Debugger** — justifica o nome "Debugger.exe" e diferencia de tudo open-source
3. **Refatorar ViewPortWindow** — janela de oportunidade antes que o monolito paralise o desenvolvimento
