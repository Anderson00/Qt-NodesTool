# Valkyrie — Qt-NodesTool: Documentação Completa

> **Versão:** Qt 6.5.3 · C++17 (GUI) · C++11 (middleware)  
> **Executável:** `Debugger.exe`  
> **Última atualização:** 2026-05-25

---

## Índice

1. [Visão Geral do Projeto](#1-visão-geral-do-projeto)
2. [Arquitetura do Sistema](#2-arquitetura-do-sistema)
3. [Build e Deploy](#3-build-e-deploy)
4. [Conceitos Fundamentais](#4-conceitos-fundamentais)
5. [Sistema de Nós — Visão Geral](#5-sistema-de-nós--visão-geral)
6. [Nós — Categoria Common](#6-nós--categoria-common)
7. [Nós — Categoria Math](#7-nós--categoria-math)
8. [Nós — Categoria Logic](#8-nós--categoria-logic)
9. [Nós — Categoria Input](#9-nós--categoria-input)
10. [Nós — Categoria Flow](#10-nós--categoria-flow)
11. [Nós — Categoria Converters](#11-nós--categoria-converters)
12. [Nós — Categoria Data](#12-nós--categoria-data)
13. [Nós — Categoria Database](#13-nós--categoria-database)
14. [Nós — Categoria Encoding](#14-nós--categoria-encoding)
15. [Nós — Categoria Networking](#15-nós--categoria-networking)
16. [Nós — Categoria System](#16-nós--categoria-system)
17. [Nós — Categoria Transform](#17-nós--categoria-transform)
18. [Nós — Categoria Visualization](#18-nós--categoria-visualization)
19. [Nós — Categoria AI](#19-nós--categoria-ai)
20. [Nós — Categoria Geo](#20-nós--categoria-geo)
21. [Nós — Categoria IO](#21-nós--categoria-io)
22. [Sistema de Desktops Virtuais](#22-sistema-de-desktops-virtuais)
23. [Sistema de Temas e Aparência](#23-sistema-de-temas-e-aparência)
24. [Componentes QML Reutilizáveis](#24-componentes-qml-reutilizáveis)
25. [Middleware](#25-middleware)
26. [Como Adicionar um Novo Nó](#26-como-adicionar-um-novo-nó)
27. [Persistência e Workspaces](#27-persistência-e-workspaces)
28. [Undo/Redo](#28-undoredo)

---

## 1. Visão Geral do Projeto

O **Valkyrie** é uma ferramenta de depuração e visualização baseada em **grafo de nós** (*node graph*). A ideia central é que o usuário conecta blocos funcionais visualmente — os **nós** — e eles trocam dados entre si através de **conexões** (arestas do grafo). Isso permite construir pipelines de processamento, visualização e controle de forma interativa, sem recompilar código.

### Para que serve

- **Depuração de sistemas embarcados / IoT** — conecte um monitor serial, processe os valores recebidos e exiba em um gráfico em tempo real.
- **Prototipagem de lógica** — encadeie operações matemáticas, comparações e gates lógicos para validar algoritmos.
- **Visualização de dados** — alimente gráficos de linha, pizza, barras e gauges com qualquer fonte de dados.
- **Integração com APIs externas** — faça requisições HTTP/REST, WebSocket, consulte banco de dados SQLite ou envie prompts à API Claude.
- **Controle de fluxo** — crie pipelines com ramificações, loops, delays e switches usando os nós de Flow.

### Tecnologias Principais

| Componente | Tecnologia |
|---|---|
| GUI | Qt 6.5.3, QtQuick, QtCharts |
| Lógica de nós | C++17 com Q_OBJECT / Q_PROPERTY |
| Middleware | Qt Core + Network (C++11) |
| Build | CMake + Visual Studio 2022 (Windows) |
| Python | pybind11 v2.11.1 + Python 3.11 embarcado |
| AI | Claude API (claude-haiku-4-5-20251001) via QNetworkAccessManager |

---

## 2. Arquitetura do Sistema

O projeto é dividido em três camadas independentes:

```
┌─────────────────────────────────────────────┐
│              valkyrieGUI                    │  ← Debugger.exe
│   Qt6 GUI · C++17 · QML/QtQuick            │
└──────────────────┬──────────────────────────┘
                   │ TCP/Socket
┌──────────────────▼──────────────────────────┐
│              middleware                     │  ← daemon separado
│   Qt Core/Network · C++11                  │
│   TcpServer, AgenteCache, Controllers      │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│              tests                          │  ← valkyrie-test
│   Google Test · cobre middleware/cache      │
└─────────────────────────────────────────────┘
```

### 2.1 valkyrieGUI — Componentes Principais

#### `MainWindow`
`QMainWindow` com MDI (Multiple Document Interface). É a janela raiz do aplicativo. Gerencia sub-janelas, menus e a abertura de `ViewPortWindow`.

#### `ViewPortWindow`
O canvas principal de edição de nós. Herda de `QMLWindow` e expõe sua API ao QML via `Q_PROPERTY` e `Q_INVOKABLE`. Responsável por:
- Gerenciar o `QHash<QString, Behaviours*>` de nós por UUID (acesso O(1))
- Integrar o `QUndoStack` para undo/redo
- Disparar sinais `onBehaviourAdded` e `onBehavioursCleared` para o QML

#### `BehaviourLoader` (singleton)
Carrega e instancia nós em tempo de execução. Consulta o `BehaviourRegistry` para criar instâncias de `Behaviours` a partir do nome da classe.

#### `BehaviourRegistry` (singleton)
Registro global de todos os tipos de nós disponíveis. Cada tipo de nó se registra automaticamente via macro no startup:

```cpp
REGISTER_BEHAVIOUR(MinhaClasse, "Nome Exibido", "Descrição", "categoria", numInputs, numOutputs)
```

O registro acontece antes de `main()` via inicialização estática de variável global. O QML acessa via `App.NodeRegistry` singleton.

#### `Behaviours` (classe base)
Todos os nós herdam de `Behaviours`, que por sua vez herda de `QObject`. Cada instância tem:
- `uuid` — identificador único
- `qmlBodyUrl` — URL do arquivo QML que renderiza a UI do nó
- `width` / `height` / `contentHeight` — dimensões do card
- `x` / `y` — posição no canvas
- `title` — nome exibido no cabeçalho do card
- Método `addInputOutputExclusion()` — lista de sinais/slots que **não** aparecem como conexões

#### `DesktopManager` (singleton)
Gerencia **desktops virtuais** dentro de um projeto. Cada desktop tem um nome, cor, e lista de UUIDs de nós membros. Nós podem ser **pinados** (visíveis em todos os desktops). Exposto ao QML como `App.Desktop 1.0`.

#### `Connections`
Representa uma aresta do grafo. Conecta um sinal de saída de um nó (`outputValue`) ao slot de entrada de outro (`setInputValue`). A conexão é feita via `QMetaObject::connect()` em runtime.

### 2.2 Fluxo de Dados entre Nós

```
NóA::outputValue(double)  ──────────────────►  NóB::setInputValue(double)
         ▲                                              │
   (Qt signal)                                    (Qt slot)
         │                                              ▼
   C++ emite                                   C++ processa e
   no momento                                  pode emitir novo
   do cálculo                                  outputValue
```

A conexão é puramente Qt signals/slots — sem overhead de serialização. O QML exibe as arestas visualmente como curvas de Bézier desenhadas com `Shape`/`PathCubic` no `ViewPortWindow.qml`.

---

## 3. Build e Deploy

### Pré-requisitos
- Qt 6.5.3 com módulos: `Widgets, Core, Svg, Gui, Sql, Quick, Network, Xml, QuickControls2, Core5Compat, Charts, Qml`
- CMake ≥ 3.16
- Visual Studio 2022 (Windows) ou equivalente

### Comandos

```bash
# 1. Configurar (Windows/VS2022)
mkdir build && cd build
cmake -G "Visual Studio 17 2022" -A x64 ..

# 2. Compilar
cmake --build . --config Release

# 3. Deploy (copia DLLs Qt necessárias)
windeployqt.exe --release build\Release\Debugger.exe

# 4. Rodar testes
ctest --output-on-failure -C Release

# 5. Rodar teste específico
ctest -R CacheTest --output-on-failure -C Release
```

### CI/CD
O workflow GitHub Actions (`.github/workflows/build.yml`) usa `jurplel/install-qt-action` para baixar Qt 6.5.3 e compila em Windows, macOS e Linux.

---

## 4. Conceitos Fundamentais

### 4.1 O que é um Nó

Um nó é a unidade básica do sistema. Ele aparece como um **card** no canvas e possui:

- **Cabeçalho** — nome do nó, botões de menu (fechar, z-order)
- **Corpo** — UI customizada definida em QML (gráficos, inputs, displays)
- **Portas de entrada (inputs)** — slots C++ expostos como conexões à esquerda do card
- **Portas de saída (outputs)** — sinais C++ expostos como conexões à direita do card

```
        ┌──────────────────────────┐
        │  Math Operation      [×] │  ← cabeçalho
   ●────┤ setA()               ├────●  outputResult(double)
   ●────┤ setB()               ├────●  outputString(QString)
        │  [+] [−] [×] [÷] ...    │  ← corpo QML
        │  Result: 42.0000         │
        │  [A] 6.00               │
        │  [B] 7.00               │
        └──────────────────────────┘
```

### 4.2 Inputs e Outputs

Cada nó tem slots (inputs) e signals (outputs). O `BehaviourRegistry` usa introspecção de `QMetaObject` para descobrir automaticamente quais signals/slots são conexões válidas — exceto os que estão na lista de exclusão (`addInputOutputExclusion`).

**Exemplo:** `MathOperation` exclui `operationChanged()`, `valueAChanged()`, etc., pois são sinais internos de atualização de propriedade QML, não saídas de dados.

### 4.3 UUID e Identificação

Cada nó recebe um UUID único na criação. O `ViewPortWindow` mantém um `QHash<QString, Behaviours*>` indexado por UUID — busca O(1) para encontrar qualquer nó a partir de sua representação QML.

### 4.4 QML Body

Cada nó define uma URL de arquivo QML em `setQmlBodyUrl("qrc:/behaviours/categoria/NomeNo.qml")`. O `ViewComponentRectV2.qml` usa um `Loader` para carregar esse arquivo dinamicamente e injeta a referência `behaviourObject` (a instância C++) no item carregado. O QML então usa `behaviourObject.propriedade` e `behaviourObject.metodo()` para interagir com o backend C++.

---

## 5. Sistema de Nós — Visão Geral

### Categorias

| Categoria | Descrição |
|---|---|
| `common` | Nós utilitários e de visualização de uso geral |
| `math` | Operações numéricas e processamento matemático |
| `logic` | Controle de fluxo, comparações e formatação |
| `input` | Nós de entrada de dados para o usuário |
| `flow` | Controle de execução sequencial (If/Else, Loop, Switch, Delay) |
| `converters` | Conversão e adaptação de tipos de dados |
| `data` | Parsers, tabelas e análise estatística |
| `database` | CSV, SQLite |
| `encoding` | Base64, Hash, Regex |
| `networking` | HTTP REST, WebSocket |
| `system` | Clipboard, interfaces de rede, processos |
| `transform` | Buffer, rate limiter, conversão de unidades |
| `visualization` | HeatMap, grafo de nós, radar chart |
| `ai` | Integração com Claude API |
| `geo` | Visualização de mapas |
| `io` | Monitor de arquivos e diretórios |
| `script` | Python, variáveis |
| `scheduling` | Agendamento de scripts (Cron, Interval, DateTime) |

### Tabela Resumo — Todos os Nós

| Nó | Categoria | Ins | Outs | Descrição curta |
|---|---|---|---|---|
| Bar Chart | common | 0 | 0 | Gráfico de barras multi-série |
| Camera Viewer | common | — | — | Visualizador de câmera |
| Components Viewer | common | 0 | 0 | Browser de componentes |
| Counter | common | 4 | 2 | Contador com step |
| File Opener | common | 0 | 1 | Seletor de arquivo |
| Gauge | common | 1 | 0 | Gauge circular com zonas de alerta |
| Hex Viewer | common | 1 | 0 | Visualizador hexadecimal |
| Line Chart | common | 13 | 0 | Gráfico de linha multi-série |
| Pie Chart | common | 0 | 0 | Gráfico de pizza/donut |
| Processes Viewer | common | 0 | 1 | Lista de processos do sistema |
| Random Generator | common | 9 | 4 | Gerador aleatório multi-modo |
| Serial Monitor | common | 0 | 1 | Terminal serial |
| Signal Generator | common | 0 | 1 | Gerador de formas de onda |
| Text Display | common | 3 | 0 | Console/log de texto |
| Clamp | math | 3 | 2 | Limita valor ao intervalo [min,max] |
| Expression Evaluator | math | — | — | Avalia expressões matemáticas arbitrárias |
| Filter | math | 1 | 1 | Filtro de sinal (MA, EMA, Median, LP) |
| Map Range | math | 1 | 1 | Mapeia intervalo de entrada → saída |
| Math Function | math | 1 | 2 | Função unária (sin, cos, sqrt, log…) |
| Math Operation | math | 2 | 2 | Operação binária (+, −, ×, ÷, %, ^) |
| Comparison | logic | 2 | 2 | Comparação numérica |
| Gate | logic | 3 | 2 | Portão condicional |
| Hub | logic | 1 | 0 | Broadcast de conexões |
| String Format | logic | 4 | 1 | Template com {A}, {B}, {C} |
| Array Input | input | 1 | 4 | Lista de strings |
| Color Input | input | 1 | 3 | Cor (hex + RGB) |
| DateTime Input | input | 1 | 3 | Data/hora formatada + timestamp |
| Dict Input | input | 1 | 4 | Dicionário chave/valor |
| Key/Value Input | input | 1 | 5 | Par rotulado chave+valor |
| Number Input | input | 1 | 5 | Número (double/int/bool/string) |
| Pair Input | input | 1 | 2 | Ponto (X, Y) |
| Text Input | input | 1 | 2 | Texto livre |
| Vec2 Input | input | 1 | 3 | Vetor 2D com preview de seta |
| Vec3 Input | input | 1 | 3 | Vetor 3D com eixos coloridos |
| Flow Start | flow | 1 | 1 | Ponto de entrada de fluxo |
| Flow End | flow | 1 | 0 | Ponto de término de fluxo |
| Flow Branch | flow | 2 | 2 | If/Else por booleano |
| Flow Delay | flow | 2 | 1 | Aguarda N ms |
| Flow Loop | flow | 3 | 3 | Repete N vezes |
| Flow Merge | flow | 3 | 1 | Qualquer entrada → saída única |
| Flow Sequence | flow | 1 | 3 | Dispara 3 saídas em ordem |
| Flow Switch | flow | 2 | 5 | Roteia por inteiro (N casos) |
| Merge Numbers | converters | 3 | 4 | Combina A+B em multi-tipo |
| Number Cast | converters | 3 | 5 | Converte double↔int↔bool↔string |
| Pair Adapter | converters | 6 | 5 | Adapta par (A,B) entre tipos |
| Data Table Viewer | data | 4 | 2 | Tabela dinâmica com sort/filter |
| JSON Parser | data | 2 | 3 | Extrai valores por dot-path |
| JSON Tree Viewer | data | 3 | 0 | Árvore JSON colapsável |
| Statistics Analyzer | data | 2 | 2 | Estatísticas descritivas + outliers |
| CSV Reader/Writer | database | 4 | 2 | Lê e escreve CSV |
| SQLite Query | database | 3 | 2 | Executa SQL em banco local |
| Base64 | encoding | 2 | 2 | Codifica/decodifica Base64 |
| Hash Generator | encoding | 2 | 1 | MD5/SHA1/SHA256/SHA512 |
| Regex Processor | encoding | 3 | 3 | Match, grupos, substituição |
| HTTP Requester | networking | 6 | 3 | REST client GET/POST/PUT/DELETE |
| WebSocket Client | networking | 3 | 4 | WebSocket bidirecional |
| Clipboard | system | 2 | 1 | Lê e escreve clipboard |
| Network Interfaces | system | 1 | 1 | Lista interfaces com IP+MAC |
| Process Launcher | system | 4 | 3 | Executa processos + captura saída |
| Buffer Accumulator | transform | 3 | 2 | Acumula N valores → batch |
| Rate Limiter | transform | 2 | 1 | Throttle / debounce |
| Unit Converter | transform | 2 | 1 | Comprimento/massa/temperatura/velocidade |
| Heat Map | visualization | 4 | 1 | Grade 2D de intensidade |
| Node Graph Viewer | visualization | 5 | 2 | Grafo com layout force-directed |
| Radar Chart | visualization | 4 | 1 | Spider chart multi-eixo |
| AI Query | ai | 4 | 3 | Prompt → Claude API → resposta |
| Map Viewer | geo | — | — | Mapa interativo com marcadores |
| File Watcher | io | 4 | 4 | Monitor de arquivos/diretórios |
| Python | script | — | — | Script Python embutido |
| Variable Monitor | script | — | — | Monitor de variáveis globais |
| Variable Reader | script | — | — | Leitura de variável global |
| Variable Writer | script | — | — | Escrita de variável global |
| Script Scheduler | scheduling | — | — | Agendamento multi-evento |
| Cron Trigger | scheduling | — | — | Gatilho por expressão cron |
| Interval Trigger | scheduling | — | — | Gatilho por intervalo |

---

## 6. Nós — Categoria Common

### 6.1 Counter

**Propósito:** Contador numérico inteiro com incremento, decremento e reset configuráveis.

**Controles:**
- Display central grande mostrando o valor atual
- Campo **Step** (NumberSpinBox) — define quanto cada clique incrementa/decrementa
- Botões **−**, **⟳ reset**, **+**

**Outputs:** `outputValue(double)`, `outputInt(int)`, `outputString(QString)`, `outputBool(bool)`

---

### 6.2 Text Display

**Propósito:** Console/log de texto em tempo real. Recebe strings de nós conectados e as acumula em um painel rolável.

**Features:** Auto-scroll, maxLines configurável (padrão 500), botão limpar, auto-scroll toggle.

**Inputs:** `appendText(QString)`, `appendLine(QString)`, `clear()`

---

### 6.3 File Opener

**Propósito:** Seletor de arquivo com preview de metadados.

**Controles:** Root, Filter, diálogo nativo, Path, Name, Size.

---

### 6.4 Hex Viewer

**Propósito:** Visualizador de dados binários em formato hexadecimal.

**Layout:** Offset | bytes hex | ASCII. Input via `onViewOutput(obj)`.

---

### 6.5 Processes Viewer

**Propósito:** Lista de processos em execução com PID, nome, CPU, memória.

---

### 6.6 Line Chart Viewer

**Propósito:** Gráfico de linha multi-série em tempo real.

**Features:** Até 8 séries, auto-scale, pan/zoom, estatísticas (last/min/max/avg), toolbar completa.

---

### 6.7 Random Generator Viewer

**Modos:** Float, Integer, Gaussian, Dice, Bool, Sequence.

**Features:** Display editável, estatísticas, precisão decimal configurável, modo auto.

---

### 6.8 Pie Chart Viewer

**Propósito:** Gráfico de pizza/donut interativo com fatias dinâmicas.

**Features:** Modo Donut, labels toggle, explode, legenda, paleta de 12 cores.

**Inputs:** `addSlice(label, value)`, `setSliceValue(index, value)`, `clearSlices()`, `removeSlice(index)`

---

### 6.9 Bar Chart Viewer

**Propósito:** Gráfico de barras multi-série com auto-scale.

**Features:** Múltiplos BarSets, toggle de valores, animação.

**Inputs:** `appendToSet(setIndex, value)`, `addSet(name)`, `clearChart()`

---

### 6.10 Gauge Viewer

**Propósito:** Indicador circular com zonas de alerta configuráveis.

**Features:** 3 zonas de cor (normal/warn/crit), agulha animada, display digital, label de unidade.

**Input:** `setInputValue(double)`

---

### 6.11 Signal Generator

**Formas de onda:** Sine, Square, Triangle, Sawtooth, Noise.

**Parâmetros:** Hz, A (amplitude), DC (offset), φ (fase), D (duty cycle).

**Preview chart:** Janela deslizante de 200 amostras.

**Output:** `outputValue(double)`, `outputString(QString)`

---

### 6.12 Serial Monitor

**Propósito:** Terminal de porta serial com send/receive log.

**Features:** Log colorido, timestamps, modo HEX, baud rate, status de conexão.

**Output:** `outputReceived(QString)`

---

## 7. Nós — Categoria Math

### 7.1 Math Operation

**Operações:** `+`, `−`, `×`, `÷`, `%`, `xⁿ`

**Inputs:** `setA(double)`, `setB(double)`, `setOperation(int)`

**Outputs:** `outputResult(double)`, `outputString(QString)`

---

### 7.2 Math Function

**Funções:** sin, cos, tan, abs, √, ln, log₁₀, eˣ, ⌊x⌋, ⌈x⌉, round

**Input:** `setInput(double)` | **Outputs:** `outputResult(double)`, `outputString(QString)`

---

### 7.3 Clamp

**Propósito:** Limita valor a [Min, Max] e calcula normalizado [0, 1].

**Visual:** Barra de progresso + campos Min/Max. **Outputs:** `outputClamped(double)`, `outputNormalized(double)`

---

### 7.4 Map Range

**Propósito:** Mapeia valor de [inMin, inMax] para [outMin, outMax].

**Fórmula:** `out = outMin + ((input - inMin) / (inMax - inMin)) × (outMax - outMin)`

**Toggle Clamp:** output nunca sai do range de saída mesmo que o input ultrapasse o range de entrada.

**Inputs:** `setInputValue(double)`, `setInMin/Max(double)`, `setOutMin/Max(double)`, `setClamp(bool)`

**Outputs:** `outputMapped(double)`, `outputString(QString)`

---

### 7.5 Filter

**Algoritmos:**

| Modo | Descrição | Parâmetro |
|---|---|---|
| MA | Moving Average | Window (2–200) |
| EMA | Exponential MA | α (0.001–1.0) |
| Median | Mediana | Window (2–200) |
| LP | Low-Pass RC | α |

**Preview chart:** Raw vs Filtered em tempo real.

**Inputs:** `setInputValue(double)`, `setFilterMode(int)`, `setWindowSize(int)`, `setAlpha(double)`, `resetFilter()`

**Outputs:** `outputFiltered(double)`, `outputString(QString)`

---

### 7.6 Expression Evaluator

**Propósito:** Avalia expressões matemáticas arbitrárias escritas como texto (ex: `sin(a) + b * 2`). Suporta variáveis `a`, `b`, `c`, constantes e funções padrão.

---

## 8. Nós — Categoria Logic

### 8.1 Comparison

**Operadores:** `==`, `≠`, `<`, `>`, `≤`, `≥`

**Display:** Indicador TRUE/FALSE animado.

**Inputs:** `setA(double)`, `setB(double)`, `setOperation(int)`

**Outputs:** `outputResult(bool)`, `outputString(QString)`

---

### 8.2 Gate

**Propósito:** Portão que passa ou bloqueia valores baseado em estado (aberto/fechado).

**Features:** Indicador de cadeado, contadores passed/blocked, botão toggle.

**Inputs:** `setInput(double)`, `setGate(bool)`, `toggle()`, `resetCounts()`

**Outputs:** `outputValue(double)`, `outputBlocked(double)`

---

### 8.3 String Format

**Sintaxe:** Template com `{A}`, `{B}`, `{C}` como placeholders.

**Exemplo:** `"T: {A}°C | H: {B}%"` com A=25.5, B=60.0 → `"T: 25.5°C | H: 60.0%"`

---

### 8.4 Hub

**Propósito:** Broadcast — retransmite um input para todas as conexões de saída.

---

## 9. Nós — Categoria Input

Nós de entrada de dados pelo usuário, substituindo o antigo `ConstantValue`. Todos emitem seu valor imediatamente ao usuário alterar o campo.

### 9.1 Number Input

**Propósito:** Envia um valor numérico configurável pelo usuário.

**Outputs:** `outputDouble(double)`, `outputInt(int)`, `outputBool(bool)`, `outputString(QString)`, `outputChanged()` (sem dado — sinaliza mudança)

---

### 9.2 Text Input

**Propósito:** Envia uma string de texto livre.

**Outputs:** `outputString(QString)`, `outputChanged()`

---

### 9.3 Color Input

**Propósito:** Seletor de cor com preview visual.

**Outputs:** `outputHex(QString)` (ex: `"#FF5733"`), `outputRed(double)`, `outputGreen(double)`, `outputBlue(double)`

---

### 9.4 DateTime Input

**Propósito:** Seletor de data e hora com formato configurável.

**Outputs:** `outputFormatted(QString)`, `outputTimestamp(double)`, `outputIso(QString)`

---

### 9.5 Vec2 Input

**Propósito:** Vetor 2D (X, Y) com preview de seta direcional em canvas.

**Outputs:** `outputX(double)`, `outputY(double)`, `outputJson(QString)` (JSON `{x, y}`)

---

### 9.6 Vec3 Input

**Propósito:** Vetor 3D (X, Y, Z) com eixos coloridos (vermelho, verde, azul).

**Outputs:** `outputX(double)`, `outputY(double)`, `outputZ(double)`

---

### 9.7 Array Input

**Propósito:** Constrói e envia uma lista de strings.

**Outputs:** `outputJson(QString)`, `outputCount(int)`, `outputFirst(QString)`, `outputLast(QString)`

---

### 9.8 Dict Input

**Propósito:** Constrói um dicionário chave/valor.

**Outputs:** `outputJson(QString)`, `outputCount(int)`, `outputKeys(QString)`, `outputValues(QString)`

---

### 9.9 Pair Input

**Propósito:** Envia um ponto (X, Y) para nós de chart.

**Outputs:** `outputX(double)`, `outputY(double)`

---

### 9.10 Key/Value Input

**Propósito:** Par rotulado para alimentar tabelas e charts.

**Outputs:** `outputKey(QString)`, `outputValue(double)`, `outputInt(int)`, `outputBool(bool)`, `outputJson(QString)`

---

## 10. Nós — Categoria Flow

Os nós de flow implementam **controle de execução sequencial** — diferente dos outros nós que transmitem dados, eles controlam *quando* outros nós executam.

### 10.1 Flow Start

**Propósito:** Ponto de entrada de um fluxo de execução. Dispara o próximo nó ao receber o trigger.

**Input:** `trigger()` | **Output:** `exec()` (execução)

---

### 10.2 Flow End

**Propósito:** Terminal de um caminho de execução. Registra que o fluxo chegou ao fim.

**Input:** `exec()`

---

### 10.3 Flow Branch

**Propósito:** If/Else — roteia execução baseado numa condição booleana.

**Inputs:** `exec()`, `setCondition(bool)`

**Outputs:** `execTrue()` (condição verdadeira), `execFalse()` (condição falsa)

---

### 10.4 Flow Delay

**Propósito:** Aguarda N milissegundos antes de passar a execução adiante.

**Inputs:** `exec()`, `setDelayMs(int)`

**Output:** `exec()` (após o delay)

---

### 10.5 Flow Loop

**Propósito:** Repete um caminho de execução N vezes e dispara um sinal de conclusão.

**Inputs:** `exec()`, `setCount(int)`, `abort()`

**Outputs:** `execBody()` (cada iteração), `execCompleted()` (ao terminar), `outputIteration(int)` (índice atual)

---

### 10.6 Flow Merge

**Propósito:** Passa qualquer uma das 3 entradas de execução para uma saída única.

**Inputs:** `exec1()`, `exec2()`, `exec3()` | **Output:** `exec()`

---

### 10.7 Flow Sequence

**Propósito:** Dispara 3 saídas em ordem (Then0 → Then1 → Then2).

**Input:** `exec()` | **Outputs:** `execThen0()`, `execThen1()`, `execThen2()`

---

### 10.8 Flow Switch

**Propósito:** Roteia execução para um de N casos baseado num inteiro.

**Inputs:** `exec()`, `setValue(int)` | **Outputs:** `execCase0()` … `execCase4()` (5 casos)

---

## 11. Nós — Categoria Converters

### 11.1 Number Cast

**Propósito:** Converte um valor numérico entre `double`, `int`, `bool` e `string`.

**Inputs:** `setInput(double)`, `setMode(int)`, `setFormat(QString)` (ex: `"0.00"`)

**Outputs:** `outputDouble(double)`, `outputInt(int)`, `outputBool(bool)`, `outputString(QString)`, `outputChanged()`

---

### 11.2 Merge Numbers

**Propósito:** Combina dois inputs numéricos A e B em saídas de par tipadas.

**Inputs:** `setA(double)`, `setB(double)`, `setMode(int)`

**Outputs:** `outputDoubleA(double)`, `outputDoubleB(double)`, `outputIntA(int)`, `outputIntB(int)`

---

### 11.3 Pair Adapter

**Propósito:** Adapta um par (A, B) entre todas as combinações de tipo int/double.

**Inputs:** `setA(double)`, `setB(double)`, `setAAsInt(int)`, `setBAsInt(int)`, `setAFromStr(QString)`, `setBFromStr(QString)`

**Outputs:** `outputDoubleA(double)`, `outputDoubleB(double)`, `outputIntA(int)`, `outputIntB(int)`, `outputJson(QString)`

---

## 12. Nós — Categoria Data

### 12.1 JSON Parser

**Propósito:** Extrai valores de um JSON usando notação dot-path (ex: `"user.address.city"`).

**Inputs:** `setJson(QString)`, `setPath(QString)`, `parse()`

**Outputs:** `outputString(QString)`, `outputDouble(double)`, `outputJson(QString)` (sub-objeto)

---

### 12.2 JSON Tree Viewer

**Propósito:** Exibe um JSON como árvore interativa e colapsável.

**Inputs:** `setJson(QString)`, `setTitle(QString)`, `clear()`

---

### 12.3 Data Table Viewer

**Propósito:** Tabela dinâmica com suporte a ordenação, filtro e seleção de linha.

**Inputs:** `setHeaders(QString)` (JSON array), `appendRow(QString)` (JSON array), `setData(QString)` (JSON matrix), `clear()`

**Outputs:** `rowClicked(int)`, `outputRowJson(QString)`

---

### 12.4 Statistics Analyzer

**Propósito:** Análise estatística descritiva em tempo real com detecção de outliers.

**Inputs:** `addSample(double)`, `reset()`

**Outputs:** `outputMean(double)`, `outputStdDev(double)`, `outputMin(double)`, `outputMax(double)`, `outputCount(int)`, `outputIsOutlier(bool)`

**Estatísticas exibidas:** count, mean, median, std dev, min, max, variance, skewness.

---

## 13. Nós — Categoria Database

### 13.1 CSV Reader/Writer

**Propósito:** Lê e escreve arquivos CSV com delimitador configurável.

**Inputs:** `setFilePath(QString)`, `setDelimiter(QString)`, `readFile()`, `writeFile()`, `appendRow(QString)`

**Outputs:** `outputRowCount(int)`, `outputJson(QString)` (array de arrays)

---

### 13.2 SQLite Query

**Propósito:** Executa queries SQL em um banco SQLite local.

**Inputs:** `setDbPath(QString)`, `setQuery(QString)`, `execute()`

**Outputs:** `outputJson(QString)` (resultset JSON), `outputRowCount(int)`, `outputError(QString)`

---

## 14. Nós — Categoria Encoding

### 14.1 Base64

**Propósito:** Codifica e decodifica strings em Base64.

**Inputs:** `setInput(QString)`, `setMode(int)` (0=encode, 1=decode)

**Outputs:** `outputResult(QString)`, `outputError(QString)`

---

### 14.2 Hash Generator

**Propósito:** Calcula hash de texto usando MD5, SHA1, SHA256 ou SHA512.

**Inputs:** `setInput(QString)`, `setAlgorithm(int)`

**Output:** `outputHash(QString)`

---

### 14.3 Regex Processor

**Propósito:** Aplica expressões regulares para match, capture de grupos e substituição.

**Inputs:** `setInput(QString)`, `setPattern(QString)`, `setReplacement(QString)`

**Outputs:** `outputMatch(bool)`, `outputCaptures(QString)` (JSON array), `outputReplaced(QString)`

---

## 15. Nós — Categoria Networking

### 15.1 HTTP Requester

**Propósito:** Cliente REST completo para GET, POST, PUT, DELETE com headers customizados.

**Inputs:** `setUrl(QString)`, `setMethod(int)`, `setBody(QString)`, `setHeader(QString)`, `setToken(QString)`, `send()`

**Outputs:** `outputBody(QString)`, `outputStatus(int)`, `outputError(QString)`

**Features:**
- Seletor de método (GET/POST/PUT/DELETE) via pill tabs
- Editor de headers (key/value pairs)
- Campo de body (JSON/raw)
- Indicador de loading animado
- Exibição do status HTTP com cor (verde 2xx, laranja 3xx, vermelho 4xx/5xx)

---

### 15.2 WebSocket Client

**Propósito:** Conexão WebSocket bidirecional para streaming em tempo real.

**Inputs:** `setUrl(QString)`, `connectWs()`, `disconnectWs()`, `send(QString)`

**Outputs:** `outputMessage(QString)`, `outputConnected(bool)`, `outputError(QString)`, `outputDisconnected()`

**Features:** Indicador de status de conexão, log de mensagens recebidas, campo de envio.

---

## 16. Nós — Categoria System

### 16.1 Clipboard

**Propósito:** Lê e escreve texto no clipboard do sistema.

**Inputs:** `copyText(QString)`, `paste()`

**Output:** `outputText(QString)` (texto lido do clipboard)

---

### 16.2 Network Interfaces

**Propósito:** Lista todas as interfaces de rede com endereços IP e MAC.

**Input:** `refresh()`

**Output:** `outputJson(QString)` (array de objetos `{name, ip, mac, isUp}`)

---

### 16.3 Process Launcher

**Propósito:** Executa comandos de sistema e captura stdout/stderr.

**Inputs:** `setProgram(QString)`, `setArguments(QString)`, `setWorkDir(QString)`, `start()`

**Outputs:** `outputStdout(QString)`, `outputStderr(QString)`, `outputExitCode(int)`

**Features:** Log de stdout/stderr em tempo real, controle de timeout, botão Kill.

---

## 17. Nós — Categoria Transform

### 17.1 Buffer Accumulator

**Propósito:** Acumula N amostras e emite como batch quando o buffer enche.

**Inputs:** `addSample(double)`, `setBufferSize(int)`, `flush()`

**Outputs:** `outputBatch(QString)` (JSON array), `outputCount(int)`

---

### 17.2 Rate Limiter

**Propósito:** Limita a frequência de passagem de dados via throttle ou debounce.

**Inputs:** `setInput(double)`, `setMode(int)` (0=throttle, 1=debounce), `setIntervalMs(int)`

**Output:** `outputValue(double)`

**Throttle:** passa no máximo 1 valor por intervalo.
**Debounce:** aguarda o sinal estabilizar por `intervalMs` antes de emitir.

---

### 17.3 Unit Converter

**Propósito:** Converte entre unidades de comprimento, massa, temperatura e velocidade.

**Inputs:** `setInput(double)`, `setCategory(int)`, `setFromUnit(int)`, `setToUnit(int)`

**Output:** `outputValue(double)` (valor convertido)

**Categorias:**
- Comprimento: m, cm, mm, km, in, ft, yd, mi
- Massa: kg, g, mg, lb, oz, t
- Temperatura: °C, °F, K
- Velocidade: m/s, km/h, mph, knots

---

## 18. Nós — Categoria Visualization

### 18.1 Heat Map Viewer

**Propósito:** Grade 2D de intensidade com gradiente de cor configurável.

**Inputs:** `setRows(int)`, `setCols(int)`, `setValue(int row, int col, double val)`, `setData(QString)`, `clear()`

**Output:** `outputClickedValue(double)` (valor clicado pelo usuário)

**Features:** Gradiente configurável (azul→vermelho, monocromático, etc.), legenda de escala, hover tooltip.

---

### 18.2 Node Graph Viewer

**Propósito:** Visualiza topologia de grafo com layout force-directed interativo.

**Inputs:** `addNode(QString id, QString label)`, `addEdge(QString from, QString to)`, `clear()`, `setGraphJson(QString)`, `removeNode(QString id)`

**Outputs:** `outputClickedNode(QString)`, `outputClickedEdge(QString)`

---

### 18.3 Radar Chart Viewer

**Propósito:** Gráfico spider/radar para comparação multi-dimensional.

**Inputs:** `setAxes(QString)` (JSON array de labels), `setValues(QString)` (JSON array), `addSeries(QString)`, `clear()`

**Output:** `outputClickedAxis(QString)`

---

## 19. Nós — Categoria AI

### 19.1 AI Query

**Propósito:** Integração com a API do Claude (Anthropic). Envia prompts e recebe respostas de LLM diretamente no grafo de nós.

**Modelo padrão:** `claude-haiku-4-5-20251001` (configurável)

**Inputs (slots):**
- `query(QString userPrompt)` — envia o prompt e inicia a requisição
- `setSystemPrompt(QString)` — define o system prompt
- `setModel(QString)` — troca o modelo
- `setApiKey(QString)` — define a chave de API

**Outputs (signals):**
- `responseReceived(QString)` — texto da resposta
- `error(QString)` — mensagem de erro
- `tokensUsed(int inputTokens, int outputTokens)` — tokens consumidos

**Propriedades QML:**
- `systemPrompt`, `model`, `maxTokens`, `isLoading`, `lastResponse`

**Features:**
- Campo de system prompt editável
- Seletor de modelo
- Campo de max tokens
- Indicador de loading animado
- Exibição da última resposta com scroll
- Contador de tokens de entrada/saída

**Uso típico:** classificar dados de entrada, sumarizar logs, gerar descrições de anomalias, processar linguagem natural em pipelines de dados.

---

## 20. Nós — Categoria Geo

### 20.1 Map Viewer

**Propósito:** Visualizador de mapa interativo com suporte a marcadores e sobreposições (polylines).

**Features:** Pan/zoom interativo, adição de marcadores por coordenadas, exibição de polylines.

> **Nota:** A implementação usa WebEngine para renderizar o mapa (OpenStreetMap via Leaflet.js ou similar).

---

## 21. Nós — Categoria IO

### 21.1 File Watcher

**Propósito:** Monitora arquivos e diretórios em tempo real, emitindo eventos quando há mudanças.

**Inputs:** `setPath(QString)`, `startWatching()`, `stopWatching()`, `addPath(QString)`

**Outputs:** `fileChanged(QString)`, `directoryChanged(QString)`, `outputChanged(bool)`, `outputPath(QString)`

**Features:** Suporte a múltiplos paths, filtro por extensão, contagem de eventos.

---

## 22. Sistema de Desktops Virtuais

O **DesktopManager** (`App.Desktop 1.0`) permite organizar nós em **desktops virtuais** dentro de um mesmo projeto — similar ao conceito de workspaces do Linux ou virtual desktops do Windows.

### Conceitos

- **Desktop** — grupo nomeado de nós com cor e ID únicos
- **Membro** — nó atribuído a um desktop específico
- **Pinado** — nó visível em todos os desktops simultaneamente
- **Viewport por desktop** — cada desktop lembra sua última posição de câmera (pan/zoom)
- **Soft limit** — máximo de 8 desktops com aviso dismissable; pode ser ultrapassado com "Add Anyway"

### API QML

```qml
// Criar desktop
DesktopManager.addDesktop("Análise de Dados")

// Navegar
DesktopManager.nextDesktop()
DesktopManager.previousDesktop()
DesktopManager.switchToDesktopByIndex(2)

// Mover nó para desktop
DesktopManager.moveNodeToDesktop(uuid, fromId, toId)

// Pinar nó (visível em todos)
DesktopManager.pinNode(uuid)

// Verificar visibilidade
DesktopManager.isNodeVisibleOnCurrentDesktop(uuid)
```

### Componentes QML do Desktop

**`DesktopBar`** — Barra horizontal de 36px com tabs de desktops. Double-click para renomear inline. Botão `+` com guard de soft limit. Arrastar tabs para reordenar.

**`DesktopOverview`** (Ctrl+Tab) — Overlay fullscreen mostrando todos os desktops como thumbnails com posições reais dos nós. Clique no thumbnail para trocar de desktop.

**`DesktopLimitWarning`** — Banner inline quando o limite de 8 desktops é atingido. Oferece "Add Anyway" para ultrapassar o limite. Descartado por sessão.

---

## 23. Sistema de Temas e Aparência

### 23.1 ThemeManager

Singleton global (`App.Theme 1.0`) que gerencia o tema visual da aplicação. Todos os componentes QML usam `ThemeManager.propriedade` para cores.

**Propriedades de cor:**

| Propriedade | Uso |
|---|---|
| `backgroundColor` | Fundo de painéis e cards |
| `surfaceColor` | Superfície de toolbars e headers |
| `textColor` | Texto principal |
| `textSecondaryColor` | Texto secundário, labels, hints |
| `borderColor` | Bordas de elementos |
| `primaryColor` | Cor de destaque principal (botões, valores) |
| `secondaryColor` | Cor secundária de destaque |
| `accentColor` | Cor de acento |
| `successColor` | Verde — sucesso, OK |
| `warningColor` | Amarelo/laranja — aviso |
| `dangerColor` | Vermelho — erro, perigo |
| `selectionColor` | Cor de seleção de texto |

### 23.2 NodeTheme

Cada nó pode ter uma cor personalizada (override) que sobrepõe a cor global do ThemeManager para aquele nó específico. Modificável via `NodeSettings` (bottom sheet do card).

### 23.3 ColorPreset e PresetManager

O `PresetManager` (singleton, `App.Presets 1.0`) gerencia paletas de cores pré-definidas e customizadas. Cada `ColorPreset` define 14 papéis de cor. Persiste no JSON local. Acessível via `SettingsPopup`.

---

## 24. Componentes QML Reutilizáveis

Todos os componentes estão em `qml/components/` e podem ser importados via caminho relativo.

### 24.1 NumericInputField

Campo de entrada numérica precisa com scroll e botões ▲/▼.

```qml
NumericInputField {
    label: "A"
    value: 42.0
    from: -1000; to: 1000; stepSize: 1.0; decimals: 2
    suffix: "ms"; showBar: true
    onValueModified: console.log(newValue)
}
```

**Interação:** digitação direta, scroll ±1, Shift+scroll ±10, Ctrl+scroll ±100.

---

### 24.2 NumberSpinBox

SpinBox temático com botões + e −. Bom para valores inteiros.

---

### 24.3 CustomSlider / CustomSliderVertical

Slider horizontal/vertical com tooltip flutuante.

> **Nas novas implementações**, `NumericInputField` é preferido sobre `CustomSlider` por oferecer precisão de digitação direta.

---

### 24.4 NewButton

Botão Material Design com variantes e efeito ripple.

```qml
NewButton { text: "Enviar"; variant: "filled" /* | "outlined" | "text" | "rounded" */ }
```

---

### 24.5 FabButton

Floating Action Button (FAB) com ripple. Usado para ações primárias flutuantes.

---

### 24.6 IconButton

Botão circular com apenas ícone. Usado em toolbars compactas.

---

### 24.7 ColorPicker

Seletor de cor interativo com swatches predefinidos e campo hex editável.

---

### 24.8 ViewComponentRectV2

**O card visual de cada nó.** Renderiza container com header, body loader, handles de resize, drag, sockets de conexão e sincronização bidirecional com C++.

---

### 24.9 CalendarView

Suporta `multiSelect`, `rangeSelect` (start/end + hover preview), `markedDates`.

---

### 24.10 TimePicker

Seletor de horas/minutos/segundos via spinners. Emite `onTimeChanged(h, m, s)`.

---

### 24.11 CodeEditor / CodeBlock

`CodeEditor` — editor Python com syntax highlighting (`PythonHighlighter`).

`CodeBlock` — exibição read-only de código.

---

## 25. Middleware

O middleware é um daemon separado que gerencia comunicação de rede. Usa apenas Qt Core e Qt Network — sem GUI.

### Componentes

| Classe | Descrição |
|---|---|
| `Agente` | Agente base com UUID e cache de parâmetros |
| `Client` | Estende Agente para conexões TCP socket |
| `AgenteCache` | Camada de caching para agentes |
| `TcpServer` | Gerencia múltiplas conexões de clientes |
| `MiddlewareController` | Controlador principal |
| `MetamorphController` | Controle de transformação/metamorfismo de processos |
| `NetworkController` | Gerenciamento de rede |
| `CommandController` | Despacho de comandos remotos |
| `MetamorphProcess` | Lógica de transformação de processos |
| `Command` / `LocalDirLsCommand` | Padrão Command para operações remotas |

### Observer Pattern

O middleware usa templates `ISubject<T>` / `IObserver<T>` para estado reativo entre componentes.

---

## 26. Como Adicionar um Novo Nó

### Passo 1 — Criar o Header C++

Crie `valkyrieGUI/src/include/behaviours/CATEGORIA/meunode.h`:

```cpp
#ifndef MEUNODE_H
#define MEUNODE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class MeuNode : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double valor READ valor NOTIFY valorChanged)

public:
    explicit MeuNode(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double valor() const;

public slots:
    void setValor(double v);         // ← input (porta de entrada)

signals:
    void outputValor(double v);       // ← output (porta de saída)
    void valorChanged();              // ← interno: exclua da lista de conexões

private:
    double m_valor = 0.0;
};

#endif
```

### Passo 2 — Criar o .cpp C++

```cpp
#include "meunode.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(MeuNode, "Meu Node", "Descrição do que faz", "common", 1, 1)

MeuNode::MeuNode(QObject *parent) : Behaviours(parent)
{
    this->setWidth(240);
    this->setHeight(180);
    this->setContentHeight(180);
    this->setQmlBodyUrl("qrc:/behaviours/common/MeuNode.qml");
    this->addInputOutputExclusion(QList<QString>({
        "valorChanged()"
    }));
}
```

### Passo 3 — Criar o QML

Crie `valkyrieGUI/resources/qml/behaviours/CATEGORIA/MeuNode.qml`:

```qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject   // ← OBRIGATÓRIO — injetado pelo Loader

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 6; spacing: 4

        Text {
            text: behaviourObject ? behaviourObject.valor.toFixed(2) : "0"
            font.pixelSize: 18
            color: ThemeManager.primaryColor
            Layout.alignment: Qt.AlignHCenter
        }

        NumericInputField {
            Layout.fillWidth: true
            label: "Val"
            value: behaviourObject ? behaviourObject.valor : 0
            onValueModified: if (behaviourObject) behaviourObject.setValor(newValue)
        }
    }
}
```

### Passo 4 — Registrar no QRC

Em `valkyrieGUI/resources/qml.qrc`:

```xml
<qresource prefix="/behaviours/common">
    <file alias="MeuNode.qml">qml/behaviours/common/MeuNode.qml</file>
</qresource>
```

### Passo 5 — Adicionar ao CMakeLists.txt

Em `valkyrieGUI/CMakeLists.txt`:

```cmake
src/include/behaviours/common/meunode.h src/include/behaviours/common/meunode.cpp
```

### Passo 6 — Compilar

```bash
cmake --build . --config Release
```

O nó aparece automaticamente no `NodesDrawer` sob a categoria definida.

---

## 27. Persistência e Workspaces

### WorkspaceManager

Singleton (`App.Workspace 1.0`) que gerencia **workspaces** — snapshots completos do estado do grafo (posição de nós, conexões, valores, desktops).

**Operações:**
- `saveWorkspace(name)` — salva o estado atual com um nome
- `loadWorkspace(name)` — restaura um workspace salvo
- `deleteWorkspace(name)` — remove um workspace
- `renameWorkspace(oldName, newName)` — renomeia

> **A partir da versão atual**, o `WorkspaceManager` também serializa o estado do `DesktopManager` — desktops, pinados e ID do desktop ativo são restaurados junto com os nós.

### GlobalProperties

Singleton (`App.Properties 1.0`) que persiste configurações globais:
- `debugMode`, `lastWorkspace`, `lastPresetId`, `snapEnabled`, `snapGridSize`

Migra automaticamente de INI legado para JSON.

### Serialização de Estado de Nó

Cada nó implementa `saveState()` → `QJsonObject` e `loadState(QJsonObject)`. O WorkspaceManager salva e restaura o estado interno de cada nó individualmente.

---

## 28. Undo/Redo

O Valkyrie implementa undo/redo completo via `QUndoStack` integrado ao `ViewPortWindow`.

### Comandos Implementados

| Comando | Classe | Mergeable |
|---|---|---|
| Adicionar nó | `AddNodeCommand` | Não |
| Remover nó | `RemoveNodeCommand` | Não |
| Mover nó | `MoveNodeCommand` | **Sim** — movimentos consecutivos do mesmo nó são fundidos |
| Adicionar conexão | `AddConnectionCommand` | Não |
| Remover conexão | `RemoveConnectionCommand` | Não |

### Merge de Movimentos

O `MoveNodeCommand` implementa `mergeWith()` do `QUndoCommand`. Quando o usuário arrastar um nó continuamente, múltiplos comandos são fundidos em um único, evitando que cada pixel ocupe uma entrada de undo.

### Atalhos

`Ctrl+Z` — Undo | `Ctrl+Y` / `Ctrl+Shift+Z` — Redo

---

*Documentação gerada em 2026-05-25 — Valkyrie Qt-NodesTool*
