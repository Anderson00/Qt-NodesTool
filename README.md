# Qt-NodesTool

[![Build](https://github.com/Anderson00/Qt-NodesTool/actions/workflows/build.yml/badge.svg)](https://github.com/Anderson00/Qt-NodesTool/actions/workflows/build.yml)

Qt-NodesTool ("Valkyrie") is a Qt 6.5.3 node-based debugger and visualization tool. Build, connect, and inspect behavior nodes visually — with workspace persistence, full undo/redo, dynamic theming, and a network middleware daemon for agent management.

## Features

- **Node canvas** — Visual node-based editing with cubic bezier connection curves, marching ants animation, and origin marker
- **Undo/Redo** — Full QUndoStack integration: add/remove/move nodes and connections are all undoable; move commands merge for smooth history
- **Workspace management** — Save, load, delete, and rename named workspaces (node graph snapshots) from the UI
- **Color presets** — Builtin and custom color palettes with 14 color roles each; saved to disk; switchable at runtime
- **Per-node theming** — `NodeTheme` per node overrides individual color roles while falling back to global theme
- **Splash screen** — Project selection dialog on startup via `SplashScreen` QML component
- **Settings popup** — Full settings UI with color preset management
- **Viewer sub-windows** — HexViewer, LineChartViewer, ProcessesViewer, CameraViewer, ComponentsViewer
- **Middleware daemon** — Qt Core/Network agent daemon (C++11) for TCP-based remote agent and process management
- **CI/CD** — GitHub Actions multi-platform builds (Windows/macOS/Linux) with artifact upload

## Build Status

| Platform | Status | Qt Version | Compiler |
|----------|--------|-----------|----------|
| ![Windows](https://img.shields.io/badge/Windows-✅%20Working-brightgreen) | ✅ Working | 6.5.3 | MinGW 64-bit |
| ![macOS](https://img.shields.io/badge/macOS-✅%20Working-brightgreen) | ✅ Working | 6.5.3 | Clang (Intel/Apple Silicon) |
| ![Linux](https://img.shields.io/badge/Linux-✅%20Working-brightgreen) | ✅ Working | 6.5.3 | GCC/Clang |

## CI/CD Pipeline

This project uses **GitHub Actions** for continuous integration and automated builds:

- **Multi-platform support**: Builds are tested on Windows, macOS, and Linux
- **Parallel compilation**: All platforms compile simultaneously for faster feedback
- **Artifact storage**: Build artifacts are automatically uploaded and retained for 30 days
- **Workflow file**: See [`.github/workflows/build.yml`](.github/workflows/build.yml) for details

Each push to `main` or `develop` branches triggers the workflow automatically.


## Requirements

To build and run Qt-NodesTool, you need the following:

- **Qt 6.5.3** development kit
  - **Windows**: MinGW 64-bit
  - **macOS**: Clang (Intel/Apple Silicon)
  - **Linux**: GCC or Clang
- **CMake** 3.16 or higher
- **C++17** compatible compiler

## Installation

1. Clone this repository:
   ```bash
   git clone --recursive https://github.com/Anderson00/Qt-NodesTool.git
   cd Qt-NodesTool
   ```

2. See [BUILD_GUIDE.md](BUILD_GUIDE.md) for platform-specific build instructions:
   - [Windows Build Instructions](BUILD_GUIDE.md#windows)
   - [macOS Build Instructions](BUILD_GUIDE.md#macos)
   - [Linux Build Instructions](BUILD_GUIDE.md#linux)

# Screenshots
![](screenshots/qt-nodes.png)