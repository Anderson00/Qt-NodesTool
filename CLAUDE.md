# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Qt-NodesTool ("Valkyrie") is a Qt 6.5.3 node-based debugger/visualization application. It has three main components: a GUI application, a network middleware daemon, and a test suite. **valkyrieGUI uses C++17; middleware uses C++11** — don't use C++17 features in middleware.

## Build Commands

**Configure (Windows, Visual Studio 2022):**
```bash
mkdir build && cd build
cmake -G "Visual Studio 17 2022" -A x64 ..
```

**Build:**
```bash
cmake --build . --config Release
```

**Deploy (Windows):**
```bash
windeployqt.exe --release build\Release\Debugger.exe
```

**Run tests:**
```bash
ctest --output-on-failure -C Release
```

**Run a single test:**
```bash
ctest -R CacheTest --output-on-failure -C Release
```

CI uses `jurplel/install-qt-action` to fetch Qt 6.5.3 — see `.github/workflows/build.yml` for platform-specific steps (Windows/macOS/Linux).

## Architecture

### Three-Tier Structure

**valkyrieGUI** — Qt6 GUI executable (output: `Debugger.exe`)

**Core classes:**
- `MainWindow` — QMainWindow with MDI (Multiple Document Interface) as the application shell
- `ViewPortWindow` — Node-based visual editing canvas; inherits from `QMLWindow` (not QWidget); exposes API to QML via `Q_PROPERTY` / `Q_INVOKABLE`; integrates `QUndoStack` for undo/redo; node snapping and viewport cloning
- `BehaviourLoader` (singleton) — Dynamically loads node behaviors from JSON; creates `Behaviours` objects at runtime; node type is a `Q_ENUM` (CPP, DLL, PYTHON)
- `BehaviourRegistry` (singleton) — Static-init self-registration system; node types register via `REGISTER_BEHAVIOUR` macro; exposed to QML as `NodeRegistry`; provides `discoverAll()` / `discoverAllToTree()` for the NodesDrawer
- `Behaviours` — Base class for all node types; each instance is identified by a UUID stored in `ViewPortWindow`'s `QHash` for O(1) lookup

**Theming:**
- `ThemeManager` / `AbstractTheme` / `SubTheme` — Layered theming system (dynamic, runtime-switchable)
- `NodeTheme` — Per-node color override layer; falls back to global `ThemeManager`; tracks overrides in `QSet<QString>`
- `PresetManager` (singleton) — Manages builtin + custom `ColorPreset` objects; persists to JSON; exposed to QML
- `ColorPreset` — Immutable-ish palette with 14 color roles: background, surface, foreground, border, shadow, primary, secondary, accent, success, warning, danger, text, textSecondary, selection

**Workspace & Settings:**
- `WorkspaceManager` (singleton) — Saves/loads/deletes/renames workspaces (node graph snapshots) to JSON; exposed to QML
- `GlobalProperties` (singleton) — Persistent QML bridge for app-level settings (debugMode, lastWorkspace, lastPresetId, snapEnabled, snapGridSize); migrates from legacy INI

**Variable System (new):**
- `VariableManager` (singleton) — Global typed-variable store; exposed to QML; persists to `variables.json`; `addInt/addList/addDict/addVec2/addVec3()` helpers
- `NodeVariable` — Single typed variable with 10 type strings: STRING, NUMBER, INT, BOOLEAN, COLOR, ARRAY, LIST, DICT, VEC2, VEC3; `parsedValue()` returns appropriate Qt type

**Python Scripting (new):**
- `PythonEngine` (singleton) — Embedded Python 3.11 via pybind11; runs scripts in a dedicated `QThread` to avoid blocking the GUI; task queue with timeout; `executeScript(PythonTask)` / `scriptFinished(PythonResult)` signal
- `PythonBehaviour` — Node type that executes user Python scripts; has `autoRun`, `timeoutMs`, `logs`, `isRunning`, `hasError` properties; `run()` / `killTask()` / `loadFromFile()` / `saveToFile()` invokables

**Services & Utilities:**
- `ToastManager` (singleton) — Queued toast notification system; exposed to QML; `show(msg, type)` where type ∈ {info, success, warning, error}
- `LogManager` (singleton) — Qt message handler bridge; exposes `lastMessage`, `lastType`, `warnCount`, `errorCount`; exposed to QML
- `Connections` — Wires signals/slots between behavior nodes
- `NodeSerialize` / `XmlSaveState` — Serialization utilities
- `ViewportGridItem` — Scene graph grid rendering
- `FastLineChart` — Optimized chart renderer
- `PythonHighlighter` — QSyntaxHighlighter for Python in CodeEditor

**Node behaviour categories:**
- `behaviours/common/` — BarChartViewer, CameraViewer, ComponentsViewer, ConstantValue, Counter, FileOpener, GaugeViewer, HexViewer, LineChartViewer, PieChartViewer, ProcessesViewer, RandomGeneratorViewer, SerialMonitor, SignalGenerator, TextDisplay, TimerNode
- `behaviours/logic/` — Comparison, Gate, Hub, StringFormat
- `behaviours/math/` — Clamp, ExpressionEvaluator, Filter, MapRange, MathFunction, MathOperation
- `behaviours/script/` — PythonBehaviour, VariableMonitor, VariableReader, VariableWriter
- `behaviours/scheduling/` — ScriptSchedulerViewer (multi-event scheduler with Interval/DateTime/Cron/Multi-Date triggers + inline CodeEditor), CronTriggerViewer (cron expression + preset chips + enable/fire controls), IntervalTriggerViewer (day/hour/min/sec spinboxes + countdown display)

**Sub-windows:**
- `DebuggerMain`, `QmlMdiSubWindow`, `TaskManagerWindow`, `TestConnectionWindow`

**QML — viewport sub-components (`components/viewport/`):**
- `ViewportGridCanvas`, `ViewportGridSGG` — Grid background renderers
- `ViewportOriginMarker` — Canvas origin crosshair
- `ViewportStatusBar` — Bottom status bar
- `ViewportTopBar` — Top action bar (undo/redo/save/history/panels)
- `ViewportBottomToolBar` — Bottom tool bar
- `HistoryPanel` — Undo history timeline panel
- `ConnectionRadialMenu` — Radial menu for connecting nodes
- `GroupFrame` — Visual grouping frame for nodes
- `CameraFrameItem` — Camera view framing overlay
- `VisualizationWindow`, `VisualizationPreview`, `FullscreenVisualization` — Viewport visualization cloning system

**QML — node visual (`components/`):**
- `ViewComponentRectV2` — Primary node visual rectangle (drag, resize, animations)
- `ViewComponentMini` — Compact node representation
- `ViewComponentRect` — Legacy node rect (kept for compatibility)
- `BaseBehaviour.qml` — Base QML for all behaviour UIs
- `ResizeHandle` — 8-direction resize handle; emits `resizeFinished(oldX,oldY,oldW,oldH,newX,newY,newW,newH)`

**QML — drawers (`components/drawers/`):**
- `NodesDrawer` — Left drawer listing available node types (queries `NodeRegistry.discoverAllToTree()`)
- `ExplorerDrawer` — File/workspace explorer
- `VariablesDrawer` — Live variable inspector (uses `VariableManager`)

**QML — sheets (`components/bottomsheets/`):**
- `NodeSettings` — Right drawer (280px); shows selected node details + Delete button
- `FolderBottomSheet` — Folder/tree picker

**QML — UI components (general):**
- Input: `CustomCheckBox`, `CustomComboBox`, `CustomDatePicker`, `CustomRadioButton`, `CustomSwitch`, `CustomTextField`, `CustomSlider`, `CustomSliderVertical`, `NumberSpinBox`, `NumericInputField`, `PasswordField`, `SearchableSelect`, `TagInput`, `MultiSelect`, `RangeSlider`, `AutocompleteInput`, `OTPInput`
- Display: `Card`, `SvgIcon`, `Icons`, `ColorIcon`, `Badge`, `Chip`, `Divider`, `StatusDot`, `Avatar`, `Skeleton`, `BreadcrumbBar`, `TabBar`, `Timeline`, `Stepper`, `Pagination`, `ProgressCircle`, `Kbd`, `EmptyState`, `VariableValueCard`
- Feedback: `Toast`, `Snackbar`, `AlertDialog`, `LoadingSpinner`
- Overlay: `ContextMenu`, `CommandPalette`, `AppToolTip`, `BottomSheet`, `SplitPane`
- Startup: `SplashScreen` — Project selection on startup
- Settings: `SettingsPopup` — Settings + color preset picker
- Editor: `CodeEditor` — Python code editor with syntax highlighting; `CodeBlock` — read-only code display
- Calendar: `CalendarView` — supports `multiSelect`, `rangeSelect` (first/second click sets start/end, fills all intermediate dates, emits `rangeChanged(start,end)` + hover preview bridge visual), and `markedDates`; `TimePicker` — hours/minutes/seconds spinners with `onTimeChanged(h,m,s)` signal
- Data: `DataTable`, `VirtualList`, `NodesList`
- Viewport utility: `FileDropZone`, `SegmentedControl`, `NewButton`, `AppBarButton`, `AppToolButton`, `CustomToolbar`, `Triangle`, `RippleEffectBackground`, `Accordion`

**middleware** — Qt Core/Network daemon for agent and network management (C++11 only)
- `Agente` — Base agent class with UUID and parameter cache
- `Client` — Extends `Agente` for TCP socket connections
- `AgenteCache` — Caching layer (tested in `tests/`)
- `TcpServer` — Manages client connections
- Controllers: `MiddlewareController`, `MetamorphController`, `NetworkController`, `CommandController`
- `MetamorphProcess` — Process transformation/metamorphism logic
- `Command` / `LocalDirLsCommand` — Command pattern for remote operations

**tests** — Google Test suite
- Executable: `valkyrie-test`
- Currently covers `middleware/model/cache.cpp`

### Key Design Patterns

- **Observer**: `ISubject<T>` / `IObserver<T>` templates in middleware for reactive state
- **Singleton**: `BehaviourLoader`, `BehaviourRegistry`, `GlobalProperties`, `PresetManager`, `WorkspaceManager`, `VariableManager`, `PythonEngine`, `ToastManager`, `LogManager` (all exposed to QML)
- **Self-registration**: `REGISTER_BEHAVIOUR(Class, DisplayName, Desc, Category, InCount, OutCount)` macro in `.cpp` — registers at static-init before `main()`
- **Command (middleware)**: `Command` base + concrete commands for network operations
- **Command (undo/redo)**: `QUndoCommand` subclasses in `valkyrieGUI/src/include/commands/` — `AddNodeCommand`, `RemoveNodeCommand`, `MoveNodeCommand` (mergeable), `AddConnectionCommand`, `RemoveConnectionCommand`
- **Factory**: `BehaviourLoader` and `BehaviourRegistry` construct `Behaviours` nodes
- **Model/View**: `TableModel`, `ConnectionModel` bind data to Qt/QML views

### External Dependencies

**Git Submodules:**
- `capstone` — Disassembly framework
- `cxxopts` — CLI argument parsing
- `retdec` — Decompilation (currently commented out in root CMakeLists)

**Embedded / vendored:**
- `pybind11 v2.11.1` — Python/C++ bindings (fetched by CMake)
- `python_env/` — Embedded Python 3.11 runtime with scipy, numpy; copied to build dir at post-build
- `Emu/deps/unicorn-1.0.3` — Unicorn Engine CPU emulator (x86, ARM, MIPS, SPARC, M68K, AArch64)

### QML Resource System

- All QML files are registered in `valkyrieGUI/resources/qml.qrc`
- New files **must** be added there manually — no auto-discovery
- Prefixes used: `/components`, `/components/viewport`, `/components/bottomsheets`, `/components/drawers`, `/subwindows`, `/behaviours`, `/behaviours/common`, `/behaviours/logic`, `/behaviours/math`, `/behaviours/script`, `/behaviours/scheduling`
