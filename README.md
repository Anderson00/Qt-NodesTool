# Qt-NodesTool

[![Build](https://github.com/Anderson00/Qt-NodesTool/actions/workflows/build.yml/badge.svg)](https://github.com/Anderson00/Qt-NodesTool/actions/workflows/build.yml)

Qt-NodesTool is a project designed to leverage the capabilities of Qt for advanced tool development. This project is built using **Qt 6.5.3**, ensuring performance and compatibility with modern systems.

## Build Status

| Platform | Status | Qt Version | Compiler |
|----------|--------|-----------|----------|
| ![Windows](https://img.shields.io/badge/Windows-✅%20Working-brightgreen) | ✅ Working | 6.5.3 | MSVC 2022 (x64) |
| ![macOS](https://img.shields.io/badge/macOS-🔄%20In%20Progress-yellow) | 🔄 In Progress | 6.5.3 | Clang (Intel/Apple Silicon) |
| ![Linux](https://img.shields.io/badge/Linux-🔄%20In%20Progress-yellow) | 🔄 In Progress | 6.5.3 | GCC/Clang |

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
  - **Windows**: MSVC 2022 (64-bit)
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