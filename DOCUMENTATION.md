# Valkyrie — Qt-NodesTool: Documentação Completa

> **Versão:** Qt 6.5.3 · C++17 (GUI) · C++11 (middleware)  
> **Executável:** `Debugger.exe`  
> **Última atualização:** 2026-05-07

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
9. [Sistema de Temas e Aparência](#9-sistema-de-temas-e-aparência)
10. [Componentes QML Reutilizáveis](#10-componentes-qml-reutilizáveis)
11. [Middleware](#11-middleware)
12. [Como Adicionar um Novo Nó](#12-como-adicionar-um-novo-nó)
13. [Persistência e Workspaces](#13-persistência-e-workspaces)
14. [Undo/Redo](#14-undoredo)

---

## 1. Visão Geral do Projeto

O **Valkyrie** é uma ferramenta de depuração e visualização baseada em **grafo de nós** (*node graph*). A ideia central é que o usuário conecta blocos funcionais visualmente — os **nós** — e eles trocam dados entre si através de **conexões** (arestas do grafo). Isso permite construir pipelines de processamento, visualização e controle de forma interativa, sem recompilar código.

### Para que serve

- **Depuração de sistemas embarcados / IoT** — conecte um monitor serial, processe os valores recebidos e exiba em um gráfico em tempo real.
- **Prototipagem de lógica** — encadeie operações matemáticas, comparações e gates lógicos para validar algoritmos.
- **Visualização de dados** — alimente gráficos de linha, pizza, barras e gauges com qualquer fonte de dados.
- **Geração de sinais de teste** — use o gerador de sinais para simular entradas e envie para outros nós.

### Tecnologias Principais

| Componente | Tecnologia |
|---|---|
| GUI | Qt 6.5.3, QtQuick, QtCharts, Qaterial (Material Design) |
| Lógica de nós | C++17 com Q_OBJECT / Q_PROPERTY |
| Middleware | Qt Core + Network (C++11) |
| Build | CMake + Visual Studio 2022 (Windows) |
| Estilo QML | Qaterial (Material You) + ThemeManager customizado |

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

### Tabela Resumo de Todos os Nós

| Nó | Categoria | Inputs | Outputs | Descrição curta |
|---|---|---|---|---|
| Constant Value | common | 0 | 4 | Emite valor fixo (número, texto ou bool) |
| Counter | common | — | — | Contador com incremento/decremento |
| Text Display | common | 3 | 0 | Log/console de texto |
| Timer Node | common | — | — | Tick periódico configurável |
| File Opener | common | — | — | Seletor de arquivo com preview |
| Hex Viewer | common | — | — | Visualizador de dados binários em hexadecimal |
| Processes Viewer | common | — | — | Lista de processos do sistema |
| Line Chart Viewer | common | — | — | Gráfico de linha multi-série em tempo real |
| Random Generator | common | — | — | Gerador de números aleatórios multi-modo |
| Components Viewer | common | — | — | Browser de componentes compostos |
| **Pie Chart Viewer** | common | 0 | 0 | Gráfico de pizza/donut interativo |
| **Bar Chart Viewer** | common | 0 | 0 | Gráfico de barras multi-série |
| **Gauge Viewer** | common | 1 | 0 | Gauge circular com zonas de alerta |
| **Signal Generator** | common | 0 | 1 | Gerador de formas de onda (sine, square...) |
| **Serial Monitor** | common | 0 | 1 | Terminal de porta serial |
| Math Operation | math | 2 | 2 | Operação aritmética binária |
| Math Function | math | 1 | 2 | Função matemática unária |
| Clamp | math | — | — | Limita valor a um intervalo com normalização |
| **Map Range** | math | 1 | 1 | Mapeia valor de um range para outro |
| **Filter** | math | 1 | 1 | Filtro de sinal (MA, EMA, Median, Low-Pass) |
| Comparison | logic | 2 | 2 | Comparação numérica (==, ≠, <, >, ≤, ≥) |
| Gate | logic | — | — | Portão controlado — passa ou bloqueia dados |
| String Format | logic | — | — | Formatação de string com template |

> **Negrito** = nós adicionados recentemente.

---

## 6. Nós — Categoria Common

### 6.1 Constant Value

**Propósito:** Fonte de valor constante. Permite ao usuário definir manualmente um número, texto ou booleano e emiti-lo para outros nós conectados.

**Modos:**
- **Number** — valor numérico (double). O campo central aceita digitação direta.
- **Text** — string de texto livre.
- **Bool** — alternância TRUE/FALSE com clique.

**Outputs:**
- `outputValue(double)` — valor numérico
- `outputString(QString)` — representação em texto
- `outputBool(bool)` — valor booleano
- `outputInt(int)` — valor convertido para inteiro

**Botão "Send":** emite o valor atual em todos os outputs simultaneamente.

**Uso típico:** alimentar outros nós com valores fixos durante testes, ou como "variável" configurável pelo usuário.

---

### 6.2 Counter

**Propósito:** Contador numérico inteiro com incremento, decremento e reset configuráveis.

**Controles:**
- Display central grande mostrando o valor atual
- Campo **Step** (NumberSpinBox) — define quanto cada clique incrementa/decrementa (1 a 100.000)
- Botão **−** — decrementa pelo step atual
- Botão **⟳** — reseta para zero
- Botão **+** — incrementa pelo step atual

**Uso típico:** contar eventos (cliques, pacotes recebidos, iterações de loop), gerar sequências numéricas.

---

### 6.3 Text Display

**Propósito:** Console/log de texto em tempo real. Recebe strings de nós conectados e as acumula em um painel rolável.

**Features:**
- Área rolável com auto-scroll ao fim quando nova linha chega
- Controle de **maxLines** (máximo de linhas mantidas em memória, padrão 500)
- Botão de limpar (lixeira)
- Botão ↓ flutuante para pular ao fim manualmente
- Destaque sutil na última linha inserida
- Placeholder exibido quando vazio

**Inputs (slots C++):**
- `appendText(QString)` — adiciona texto à última linha (sem quebra)
- `appendLine(QString)` — adiciona uma nova linha completa
- `clear()` — limpa todo o log

**Uso típico:** exibir logs de debug, output de processamento, dados formatados vindos de String Format.

---

### 6.4 Timer Node

**Propósito:** Gerador de pulsos (ticks) em intervalo configurável. Usado para acionar outros nós periodicamente.

**Controles:**
- Display de **contagem de ticks** com indicador de ativo (ponto verde pulsando)
- Campo **intervalo** em milissegundos (NumericInputField, 1ms a 60.000ms)
- Botão **▶ Start / ■ Stop**
- Botão **Pulse** — dispara um único tick manualmente

**Uso típico:** acionar o Signal Generator, o Random Generator ou qualquer nó que precise de tick regular. Conecte `trigger()` ou o output do timer ao input desejado.

---

### 6.5 File Opener

**Propósito:** Seletor de arquivo do sistema de arquivos com preview de metadados.

**Controles:**
- Campo **Root** — diretório inicial para o diálogo (padrão: `.`)
- Campo **Filter** — filtro de extensão (ex: `*.exe`, `*.json`)
- Botão de pasta — abre o diálogo nativo do OS
- Campo **Path** — caminho completo do arquivo selecionado (editável)
- Campo **Name** — nome do arquivo (somente leitura)
- Campo **Size** — tamanho em MB (somente leitura)

**Uso típico:** selecionar arquivos para alimentar outros nós (Hex Viewer, parsers, etc.).

---

### 6.6 Hex Viewer

**Propósito:** Visualizador de dados binários em formato hexadecimal, similar a um editor hex.

**Layout:**
- Coluna **Offset** — posição em memória
- Colunas de **bytes** em hex (00–FF por coluna)
- Coluna **ASCII** — representação ASCII dos bytes

**Input:** recebe dados via sinal `onViewOutput(obj)` onde `obj` é um array de objetos `{ offset, bytes[] }`.

**Uso típico:** inspecionar buffers de rede, protocolos binários, dados de arquivos brutos.

---

### 6.7 Processes Viewer

**Propósito:** Lista de processos em execução no sistema operacional, atualizada em tempo real.

**Features:**
- Lista com PID, nome, uso de CPU/memória
- Atualização periódica automática

**Uso típico:** monitorar processos do sistema enquanto depura aplicações.

---

### 6.8 Line Chart Viewer

**Propósito:** Gráfico de linha multi-série em tempo real com suporte a múltiplos canais de dados.

**Features:**
- Até 8 séries simultâneas com paleta de cores automática
- **Auto-scale** dos eixos X e Y (desligável)
- Pan com arrastar, zoom com scroll do mouse
- Barra de estatísticas por série: last, min, max, avg, contagem de pontos
- Toolbar completa: legend, grid, pontos visíveis, animação, auto-scale, zoom in/out/reset, clear

**Inputs via sinais C++ → QML (Connections):**
- `onInternalAppendXY(x, y)` — adiciona ponto (x, y) à série 0
- `onInternalappendYAutoIncrementX(y)` — adiciona y à série 0 com X automático
- `onInternalAppendYAutoIncrementXChannel2(y)` — adiciona à série 1
- `onInternalAppendXYToSeries(idx, x, y)` — adiciona a série específica
- `onInternalClearChart()` — limpa todas as séries
- `onInternalSetXRange(min, max)` — define range X manualmente
- `onInternalSetYRange(min, max)` — define range Y manualmente

**Uso típico:** monitorar valores de sensores, visualizar sinais de áudio/vibração, plotar resultados de algoritmos.

---

### 6.9 Random Generator Viewer

**Propósito:** Gerador de valores aleatórios com múltiplos modos de distribuição.

**Modos:**

| Modo | Descrição | Parâmetros |
|---|---|---|
| **Float** | Uniforme decimal | Min, Max |
| **Integer** | Uniforme inteiro | Min, Max |
| **Gaussian** | Distribuição normal | Min, Max, Média (μ), Desvio padrão (σ) |
| **Dice** | Lançamento de dados | Quantidade, Faces (ex: 2d6) |
| **Bool** | Booleano com probabilidade | Probabilidade P (0–100%) |
| **Sequence** | Sequência com min/max | Min, Max |

**Features:**
- Display editável do último valor gerado (permite injetar valor manual)
- Barra de estatísticas: n, min, avg, max com botão de reset
- Precisão decimal configurável (0 a 8 casas) via pill selector
- Controle de intervalo para modo automático (NumericInputField em ms)
- Botões **▶ Auto** e **Step** (geração única)

**Output:** `outputValue(double)`, `outputString(QString)`

**Uso típico:** simular dados de sensores ruidosos, testar comportamento de filtros com dados aleatórios, gerar sequências de teste.

---

### 6.10 Pie Chart Viewer *(novo)*

**Propósito:** Gráfico de pizza ou donut interativo com fatias (slices) dinâmicas.

**Features:**
- Adicionar fatias via formulário (label + valor numérico)
- Paleta de cores automática (até 12 cores distintas)
- **Modo Donut** — abre o centro do gráfico (toggle ◎)
- **Toggle de labels** — mostra/oculta os rótulos das fatias
- **Explode** — clique em uma fatia para destacá-la
- Legenda integrada do QtCharts
- Botão de limpar todas as fatias

**Inputs C++ (via slots):**
- `addSlice(label, value)` — adiciona fatia
- `setSliceValue(index, value)` — atualiza valor de fatia existente
- `clearSlices()` — remove todas
- `removeSlice(index)` — remove fatia por índice

**Uso típico:** mostrar distribuição percentual de categorias (uso de memória por módulo, erros por tipo, etc.).

---

### 6.11 Bar Chart Viewer *(novo)*

**Propósito:** Gráfico de barras com múltiplos sets de dados, auto-scale e configuração visual.

**Features:**
- Múltiplos sets (BarSet) com cores automáticas da paleta
- Formulário para append: seleciona o set e o valor
- **Toggle Show Values** — exibe os valores sobre as barras
- Animação de série ao adicionar dados
- Legenda na base do gráfico
- Botão clear

**Inputs C++ (via slots):**
- `appendToSet(setIndex, value)` — adiciona valor a um set
- `addSet(name)` — cria novo set
- `clearChart()` — limpa tudo

**Uso típico:** comparar valores entre categorias discretas, histogramas, rankings.

---

### 6.12 Gauge Viewer *(novo)*

**Propósito:** Indicador circular (tipo velocímetro/manômetro) para monitorar um único valor numérico com zonas de alerta visuais.

**Features:**
- Arco principal desenhado em Canvas com animação suave (250ms, easing OutCubic)
- **3 zonas de cor configuráveis:**
  - Verde (low) — operação normal
  - Laranja (warn) — atenção
  - Vermelho (crit) — crítico
- Agulha animada e hub central
- Display digital do valor no centro
- Labels de min/max nos extremos do arco
- Campo de unidade (ex: "RPM", "°C", "%")
- Configuração inline: Min, Max, Warn threshold, Crit threshold

**Input C++:**
- `setInputValue(double)` — atualiza o valor exibido

**Parâmetros configuráveis:**
- Min/Max do range
- Limiar de warn e crit
- Rótulo de unidade
- Valor manual (quando sem conexão)

**Uso típico:** monitorar temperatura de processador, RPM de motor, nível de bateria, uso de CPU.

---

### 6.13 Signal Generator *(novo)*

**Propósito:** Gerador de formas de onda matemáticas em tempo real. Produz valores numéricos seguindo padrões de sinal contínuos.

**Formas de onda disponíveis:**

| Modo | Fórmula |
|---|---|
| **Sine** | `A × sin(2π·f·t + φ) + DC` |
| **Square** | +A quando fase < D%, −A caso contrário |
| **Triangle** | Onda triangular simétrica com período 1/f |
| **Sawtooth** | Rampa ascendente de +A a −A por período |
| **Noise** | Ruído branco uniforme entre −A e +A |

**Parâmetros:**
- **Hz** — frequência (0.001 a 10.000 Hz)
- **A** — amplitude
- **DC** — offset DC (deslocamento vertical)
- **φ** — fase em graus (0–360°)
- **D** — duty cycle em % (apenas Square)

**Preview chart:**
- Janela deslizante de 200 amostras
- Eixo X sempre acompanha o sampleCount atual (rolling window)
- Badge de identificação da forma de onda ativa

**Controles:**
- **▶ Generate / ■ Stop** — inicia/para geração automática
- **Step** — gera uma única amostra
- **⟳** — reseta tempo e limpa chart

**Output C++:** `outputValue(double)`, `outputString(QString)`

**Uso típico:** testar filtros (conecte a saída ao Filter), simular sensores analógicos, calibrar displays de gráfico.

---

### 6.14 Serial Monitor *(novo)*

**Propósito:** Terminal de comunicação serial — monitora e exibe dados recebidos e enviados por uma porta serial, similar ao Serial Monitor do Arduino IDE.

**Features:**
- Log colorido: **recebido** (cor do texto) vs **enviado** (cor primary)
- Suporte a até 500 linhas (auto-rotação)
- **Auto-scroll** para o fim quando nova linha chega (toggle ⬇)
- **Timestamps** opcionais com precisão de millisegundo (toggle ⏱)
- **Modo HEX** — exibe dados em hexadecimal (toggle HX)
- Seletor de **baud rate** integrado: 300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600
- Indicador de **status de conexão** (verde pulsando = conectado)
- Barra de **envio**: campo de texto + toggle `\n`/`raw` + botão Send
- Enter no campo de envio dispara automaticamente
- Contador de linhas e bytes

**Inputs C++ (via slots):**
- `sendData(QString)` — envia dado pela serial (e exibe no log)
- `setBaud(int)` — configura baud rate
- `setPort(QString)` — define a porta (ex: "COM3")
- `connectPort()` / `disconnectPort()` — gerencia conexão

**Sinais C++ → QML:**
- `internalRxData(QString)` — exibe dado recebido no log
- `internalTxData(QString)` — exibe dado enviado no log
- `internalClear()` — limpa o log

**Output C++:** `outputReceived(QString)` — dado recebido (para processar em outros nós)

> **Nota:** O stub C++ inclui a estrutura completa de comunicação. A integração real com `QSerialPort` (não incluído no Qt 6 padrão — requer módulo `Qt6::SerialPort`) deve ser adicionada ao `serialmonitor.cpp` conectando os slots às APIs do `QSerialPort`.

**Uso típico:** depurar firmware embarcado, monitorar microcontroladores (Arduino, ESP32, STM32), visualizar dados de protocolos seriais.

---

## 7. Nós — Categoria Math

### 7.1 Math Operation

**Propósito:** Realiza uma operação aritmética binária (A op B) e emite o resultado.

**Operações disponíveis:**

| Símbolo | Operação | Tratamento especial |
|---|---|---|
| `+` | Adição | — |
| `−` | Subtração | — |
| `×` | Multiplicação | — |
| `÷` | Divisão | B=0 → NaN |
| `%` | Módulo | B=0 → NaN |
| `xⁿ` | Potência (A^B) | usa `std::pow` |

**Inputs:**
- `setA(double)` — define o operando A
- `setB(double)` — define o operando B
- `setOperation(int)` — seleciona a operação

**Outputs:**
- `outputResult(double)` — resultado numérico
- `outputString(QString)` — resultado como texto

**UI:**
- Seletor de operação em pill tabs com cor distinta por operação
- Display do resultado com 4 casas decimais
- Fórmula "A op B" exibida abaixo
- Inputs A e B via **NumericInputField** (digitação direta + scroll)

---

### 7.2 Math Function

**Propósito:** Aplica uma função matemática unária f(x) e emite o resultado.

**Funções disponíveis:**

| Função | Descrição |
|---|---|
| `sin` | Seno (radianos) |
| `cos` | Cosseno (radianos) |
| `tan` | Tangente (radianos) |
| `abs` | Valor absoluto |
| `√` | Raiz quadrada |
| `ln` | Logaritmo natural |
| `log₁₀` | Logaritmo base 10 |
| `eˣ` | Exponencial (e^x) |
| `⌊x⌋` | Piso (floor) |
| `⌈x⌉` | Teto (ceil) |
| `round` | Arredondamento |

**Input:** `setInput(double)` — valor de entrada x

**Outputs:**
- `outputResult(double)` — f(x) com 6 casas
- `outputString(QString)` — resultado como texto

---

### 7.3 Clamp

**Propósito:** Limita um valor de entrada ao intervalo [Min, Max] e calcula o valor normalizado no range.

**Saídas calculadas:**
- `clampedValue` — valor após limitação
- `normalized` — posição no range [0.0, 1.0], onde 0 = Min e 1 = Max

**Visual:**
- Display com o valor "Clamped" e "Normalized"
- Barra de progresso mostrando visualmente onde o valor está no intervalo
- Campos Min e Max via NumericInputField

**Uso típico:** garantir que um valor nunca ultrapasse limites seguros antes de alimentar outro nó (ex: limitar PWM antes de enviar ao hardware).

---

### 7.4 Map Range *(novo)*

**Propósito:** Mapeia um valor de entrada de um intervalo [inMin, inMax] para outro intervalo de saída [outMin, outMax]. Essencialmente a função `map()` do Arduino.

**Fórmula:**
```
out = outMin + ((input - inMin) / (inMax - inMin)) × (outMax - outMin)
```

**Features:**
- Visualização com duas barras de progresso: posição do input no range de entrada e posição do output no range de saída
- Fórmula exibida: `[inMin, inMax] → [outMin, outMax]`
- Toggle **Clamp** — se ligado, o output nunca ultrapassa [outMin, outMax] mesmo se o input sair do range

**Inputs C++:**
- `setInputValue(double)` — valor a mapear
- `setInMin(double)`, `setInMax(double)` — range de entrada
- `setOutMin(double)`, `setOutMax(double)` — range de saída
- `setClamp(bool)` — habilita/desabilita clamping

**Output C++:**
- `outputMapped(double)` — valor mapeado
- `outputString(QString)` — como texto

**Uso típico:** converter leitura de ADC (0–4095) para tensão (0–3.3V), mapear ângulo de servo (0–180°) para duty cycle de PWM.

---

### 7.5 Filter *(novo)*

**Propósito:** Filtra um sinal numérico para remover ruído, usando um dos quatro algoritmos de filtragem.

**Algoritmos:**

| Modo | Nome | Descrição | Parâmetro |
|---|---|---|---|
| **MA** | Moving Average | Média das últimas N amostras | Window (2–200) |
| **EMA** | Exponential MA | Média ponderada exponencialmente | α (0.001–1.0) |
| **Median** | Median Filter | Mediana das últimas N amostras | Window (2–200) |
| **LP** | Low-Pass RC | Filtro passa-baixa digital discreto | α (equivale a RC) |

**Como funciona o α (EMA e LP):**
- `α = 0` → saída nunca muda (sem filtragem)
- `α = 1` → saída = entrada (sem suavização)
- Valores entre 0.01 e 0.3 são típicos para suavização média

**Features:**
- Display: **Raw** (valor bruto) → **Filtered** (valor filtrado)
- Preview chart mostrando linha raw (transparente) e linha filtered (colorida)
- Ao trocar de modo, o buffer interno é resetado automaticamente
- Botão **Reset** — zera o buffer sem mudar modo

**Inputs C++:**
- `setInputValue(double)` — nova amostra bruta
- `setFilterMode(int)` — 0=MA, 1=EMA, 2=Median, 3=LP
- `setWindowSize(int)` — tamanho da janela (MA e Median)
- `setAlpha(double)` — coeficiente de suavização (EMA e LP)
- `resetFilter()` — limpa buffer

**Output C++:**
- `outputFiltered(double)` — valor filtrado
- `outputString(QString)` — como texto

**Uso típico:** suavizar leituras de sensores ruidosos antes de exibir num gauge ou gráfico; remover spikes de um sinal de velocidade.

---

## 8. Nós — Categoria Logic

### 8.1 Comparison

**Propósito:** Compara dois valores numéricos usando um operador relacional e emite o resultado booleano.

**Operadores:**

| Símbolo | Significado |
|---|---|
| `==` | Igual |
| `≠` | Diferente |
| `<` | Menor que |
| `>` | Maior que |
| `≤` | Menor ou igual |
| `≥` | Maior ou igual |

**Display:** Indicador grande **TRUE** (verde) / **FALSE** (vermelho) com animação de cor. Fórmula "A op B" exibida com 4 casas decimais.

**Inputs:**
- `setA(double)` — operando A
- `setB(double)` — operando B
- `setOperation(int)` — operador

**Outputs:**
- `outputResult(bool)` — resultado da comparação
- `outputString(QString)` — "true" ou "false"

**Uso típico:** condicionar o Gate (ligar/desligar passagem de dados baseado em uma condição), disparar alertas.

---

### 8.2 Gate

**Propósito:** Portão controlado que passa ou bloqueia um valor numérico baseado em seu estado (aberto/fechado).

**Comportamento:**
- **OPEN** (aberto, verde): o valor recebido em `setInput()` é emitido imediatamente em `outputValue()`
- **CLOSED** (fechado, vermelho): o valor recebido é bloqueado e emitido em `outputBlocked()`

**Features:**
- Indicador de estado com ícone de cadeado (Qaterial Icons)
- Contadores de **passed** (valores que passaram) e **blocked** (bloqueados)
- Clique no indicador ou no botão para alternar o estado
- Botão "Open Gate" / "Close Gate"

**Inputs:**
- `setInput(double)` — valor a filtrar
- `setGate(bool)` / `toggle()` — controla estado do gate
- `resetCounts()` — zera contadores

**Outputs:**
- `outputValue(double)` — valor que passou
- `outputBlocked(double)` — valor que foi bloqueado

**Uso típico:** habilitar/desabilitar o fluxo de dados baseado numa condição do Comparison; criar "switches" no grafo.

---

### 8.3 String Format

**Propósito:** Formata uma string usando um template com placeholders, similar ao `printf` simplificado.

**Sintaxe do template:** Use `{A}`, `{B}`, `{C}` como placeholders para os valores de entrada A, B e C.

**Exemplo:**
- Template: `"Temperatura: {A}°C | Humidade: {B}%"`
- A = 25.5, B = 60.0
- Resultado: `"Temperatura: 25.5°C | Humidade: 60.0%"`

**Features:**
- Campo de template editável com hint "Use {A}, {B}, {C} as placeholders"
- Preview do resultado em tempo real
- **Seletor de precisão decimal** (0 a 8 casas) via pill buttons

**Parâmetros:**
- `setTemplate(QString)` — define o template
- `setPrecision(int)` — casas decimais dos valores numéricos

**Outputs:**
- `resultStr` (propriedade) — string formatada (acessada pela UI QML)

**Uso típico:** construir mensagens de log formatadas antes de enviar ao Text Display, formatar dados para exibição.

---

## 9. Sistema de Temas e Aparência

### 9.1 ThemeManager

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

### 9.2 NodeTheme

Cada nó pode ter uma cor personalizada (override) que sobrepõe a cor global do ThemeManager para aquele nó específico. Modificável via `NodeSettings` (bottom sheet do card).

### 9.3 ColorPreset e PresetManager

O `PresetManager` (singleton, `App.Presets 1.0`) gerencia paletas de cores pré-definidas e customizadas. Cada `ColorPreset` define 14 papéis de cor. Persiste no JSON local. Acessível via `SettingsPopup`.

---

## 10. Componentes QML Reutilizáveis

Todos os componentes abaixo estão em `qml/components/` e podem ser importados via `import '../../components'` (ou caminho relativo equivalente).

### 10.1 NumericInputField *(novo)*

Campo de entrada numérica precisa que substitui sliders onde precisão importa.

```qml
NumericInputField {
    label: "A"          // rótulo colorido à esquerda
    value: 42.0         // valor atual
    from: -1000         // limite inferior (soft)
    to: 1000            // limite superior (soft)
    stepSize: 1.0       // passo por clique/scroll
    decimals: 2         // casas decimais exibidas
    suffix: "ms"        // texto após o valor
    showBar: true       // mostra barra de progresso na base
    accentColor: "#2ecc71"
    onValueModified: console.log(newValue)
}
```

**Interação:**
- **Digitação direta** — clique no campo e digite qualquer valor
- **Scroll do mouse** — ±1 step
- **Shift + Scroll** — ±10 steps
- **Ctrl + Scroll** — ±100 steps
- **Botões ▲/▼** — ±1 step por clique

### 10.2 NumberSpinBox

SpinBox temático com botões + e − integrados. Bom para valores inteiros com range pequeno.

```qml
NumberSpinBox {
    from: 0; to: 100; stepSize: 1; value: 50
    accentColor: ThemeManager.primaryColor
    suffixText: "pts"
}
```

### 10.3 CustomSlider

Slider horizontal com tooltip flutuante mostrando o valor atual.

```qml
CustomSlider {
    from: 0; to: 100; value: 50
    color: "#3498db"
    prefix: " ms"
    onMoved: console.log(value)
}
```

> **Nota:** Nas novas implementações, `NumericInputField` é preferido sobre `CustomSlider` por oferecer precisão de digitação direta.

### 10.4 NewButton

Botão Material Design com variantes e efeito ripple.

```qml
NewButton {
    text: "Enviar"
    variant: "filled"    // "filled" | "outlined" | "text" | "rounded"
    backgroundColor: ThemeManager.primaryColor
    onClicked: minhaFuncao()
}
```

### 10.5 CustomSwitch

Toggle switch (liga/desliga) estilizado.

```qml
CustomSwitch {
    checked: true
    onCheckedChanged: console.log(checked)
}
```

### 10.6 CustomComboBox

ComboBox temático com itens e valor selecionado.

### 10.7 ColorPicker

Seletor de cor interativo com swatches e campo hex. Usado no `SettingsPopup`.

### 10.8 ViewComponentRectV2

**O card visual de cada nó.** Componente QML que renderiza o container do nó com:
- Header com título e menu de contexto
- Loader que carrega o QML body do nó (via `bodySourceQML`)
- Handles de resize nos 8 cantos/bordas
- Drag no header para mover
- Listagem de inputs (esquerda) e outputs (direita) como sockets de conexão clicáveis
- Animação de `height` e `width` ao redimensionar
- Sincronização bidirecional com o C++ (posição, tamanho)

---

## 11. Middleware

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

## 12. Como Adicionar um Novo Nó

Este é o processo completo para adicionar um nó ao sistema.

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
    void setValor(double v);         // ← input (aparece como porta de entrada)

signals:
    void outputValor(double v);       // ← output (aparece como porta de saída)
    void valorChanged();              // ← interno, exclua da lista de conexões

private:
    double m_valor = 0.0;
};

#endif
```

### Passo 2 — Criar o .cpp C++

```cpp
#include "meunode.h"
#include "behaviours/behaviourregistry.h"

// Registra automaticamente no startup
REGISTER_BEHAVIOUR(MeuNode, "Meu Node", "Descrição do que faz", "common", 1, 1)

MeuNode::MeuNode(QObject *parent) : Behaviours(parent)
{
    this->setWidth(240);
    this->setHeight(180);
    this->setContentHeight(180);
    this->setQmlBodyUrl("qrc:/behaviours/common/MeuNode.qml");
    this->addInputOutputExclusion(QList<QString>({
        "valorChanged()"   // sinais internos não são conexões
    }));
}

// ... implementação dos métodos
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
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // Display do valor atual
        Text {
            text: behaviourObject ? behaviourObject.valor.toFixed(2) : "0"
            font.pixelSize: 18
            color: ThemeManager.primaryColor
            Layout.alignment: Qt.AlignHCenter
        }

        // Input do usuário
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

Em `valkyrieGUI/resources/qml.qrc`, adicione dentro do grupo correto:

```xml
<qresource prefix="/behaviours/common">
    <!-- ... existentes ... -->
    <file alias="MeuNode.qml">qml/behaviours/common/MeuNode.qml</file>
</qresource>
```

### Passo 5 — Adicionar ao CMakeLists.txt

Em `valkyrieGUI/CMakeLists.txt`, na lista `PROJECT_SOURCES`:

```cmake
src/include/behaviours/common/meunode.h src/include/behaviours/common/meunode.cpp
```

### Passo 6 — Compilar

```bash
cmake --build . --config Release
```

O nó aparece automaticamente no `NodesDrawer` sob a categoria definida.

---

## 13. Persistência e Workspaces

### WorkspaceManager

Singleton (`App.Workspace 1.0`) que gerencia **workspaces** — snapshots completos do estado do grafo (posição de nós, conexões, valores).

**Operações:**
- `saveWorkspace(name)` — salva o estado atual com um nome
- `loadWorkspace(name)` — restaura um workspace salvo
- `deleteWorkspace(name)` — remove um workspace
- `renameWorkspace(oldName, newName)` — renomeia

Os workspaces são persistidos como JSON no disco. O `SplashScreen` exibe a lista de workspaces ao iniciar e permite selecionar ou criar um novo.

### GlobalProperties

Singleton (`App.Properties 1.0`) que persiste configurações globais da aplicação:
- `debugMode` — modo de depuração ativo
- `lastWorkspace` — último workspace aberto
- `lastPresetId` — último preset de cores ativo

Migra automaticamente de formato INI legado para o novo formato JSON.

### Serialização de Estado de Nó

Cada nó implementa `saveState()` → `QJsonObject` e `loadState(QJsonObject)`. Isso permite que o WorkspaceManager salve e restaure o estado interno de cada nó individualmente.

---

## 14. Undo/Redo

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

O `MoveNodeCommand` implementa `mergeWith()` do `QUndoCommand`. Quando o usuário arrastar um nó continuamente, múltiplos comandos de movimento são fundidos em um único comando no stack, evitando que cada pixel de movimento ocupe uma entrada de undo.

### Atalhos

O undo/redo é acionado via os atalhos padrão (`Ctrl+Z` / `Ctrl+Y` ou `Ctrl+Shift+Z`) configurados pelo `QUndoStack`.

---

*Documentação gerada em 2026-05-07 — Valkyrie Qt-NodesTool*
