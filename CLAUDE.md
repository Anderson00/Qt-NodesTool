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
- `MainWindow` — QMainWindow with MDI (Multiple Document Interface) as the application shell
- `ViewPortWindow` — The node-based visual editing canvas; inherits from `QMLWindow` (not QWidget) and exposes its API to QML via `Q_PROPERTY` / `Q_INVOKABLE`
- `BehaviourLoader` (singleton) — Dynamically loads node behaviors from JSON; creates `Behaviours` objects at runtime; node type is a `Q_ENUM` (CPP, DLL, PYTHON)
- `Behaviours` — Base class for all node types; each instance is identified by a UUID stored in `ViewPortWindow`'s `QHash` for O(1) lookup
- `Connections` — Wires signals/slots between behavior nodes
- `ThemeManager` / `AbstractTheme` / `SubTheme` — Layered theming system
- Various viewer sub-windows: HexViewer, LineChartViewer, ProcessesViewer, CameraViewer, etc.
- QML integration via Qaterial (Material Design); middleware is deliberately GUI-free (Qt Core/Network only)

**middleware** — Qt Core/Network daemon for agent and network management
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
- **Singleton**: `BehaviourLoader::instance()`, `GlobalProperties::instance()` (QML bridge)
- **Command**: `Command` base + concrete commands for network operations
- **Factory**: `BehaviourLoader` constructs `Behaviours` nodes from JSON descriptors
- **Model/View**: `TableModel`, `ConnectionModel` bind data to Qt/QML views

### External Dependencies (Git Submodules)

- `capstone` — Disassembly framework
- `cxxopts` — CLI argument parsing
- `retdec` — Decompilation (currently commented out in root CMakeLists)
