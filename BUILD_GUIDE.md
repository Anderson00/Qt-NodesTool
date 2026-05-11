# Qt-NodesTool Build Guide

Este guia explica como fazer build do Qt-NodesTool localmente em diferentes plataformas.

## Pré-requisitos Gerais

- **Git** com suporte a submodules
- **CMake** 3.16 ou superior
- **Qt 6.5.3** SDK
- Compilador compatível com C++17

## Windows

### Pré-requisitos
- **Qt 6.5.3 for MinGW 64-bit** (via Qt Online Installer — incluir o componente MinGW 64-bit)
- O MinGW 64-bit bundlado com o Qt já é suficiente; não é necessário Visual Studio

### Build Steps

```bash
# Clone com submodules
git clone --recursive https://github.com/Anderson00/Qt-NodesTool.git
cd Qt-NodesTool

# Configure
mkdir build
cd build
cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_PREFIX_PATH="C:/Qt/6.5.3/mingw_64" ..

# Build
cmake --build . -j8

# Deploy Qt dependencies
$qtPath = "C:\Qt\6.5.3\mingw_64"  # Ajustar para sua instalação
$env:PATH = "$qtPath\bin;$env:PATH"
& "$qtPath\bin\windeployqt.exe" --release valkyrieGUI.exe
```

## macOS

### Pré-requisitos
- **Xcode Command Line Tools**
  ```bash
  xcode-select --install
  ```
- **Homebrew**
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- **Qt 6.5.3 for Clang 64-bit** (via Qt Online Installer)
- **Ninja** (recomendado)
  ```bash
  brew install ninja
  ```

### Build Steps

```bash
# Clone com submodules
git clone --recursive https://github.com/Anderson00/Qt-NodesTool.git
cd Qt-NodesTool

# Configure
mkdir build
cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="/Users/$(whoami)/Qt/6.5.3/macos" ..

# Build
cmake --build .

# Create DMG (opcional)
cd ..
macdeployqt build/valkyrieGUI.app -dmg
```

## Linux

### Pré-requisitos (Ubuntu/Debian)

```bash
# Instalar dependências
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake ninja-build \
  libgl1-mesa-dev libxkbcommon-x11-dev libxkbcommon0 \
  libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
  libxcb-randr0 libxcb-render-util0 libxcb-render0 \
  libxcb-shape0 libxcb-sync1 libxcb-xfixes0 \
  libxcb-xinerama0 libxcb-xkb1 libxkb-common-x11-0

# Qt 6.5.3 for Linux (via Qt Online Installer)
```

### Build Steps

```bash
# Clone com submodules
git clone --recursive https://github.com/Anderson00/Qt-NodesTool.git
cd Qt-NodesTool

# Configure
mkdir build
cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.5.3/gcc_64" ..

# Build
cmake --build . -j$(nproc)

# (Opcional) Create AppImage
# Instalar appimagetool e usar linuxdeployqt
linuxdeployqt build/valkyrieGUI -appimage
```

## Troubleshooting

### Windows
- **Qt not found**: Adicionar Qt bin ao PATH ou usar `-DCMAKE_PREFIX_PATH`
- **MinGW not found**: Adicionar `C:\Qt\Tools\mingw1120_64\bin` ao PATH antes de rodar cmake
- **cmake generator error**: Garantir que `cmake -G "MinGW Makefiles"` seja usado, não o gerador Visual Studio

### macOS
- **Cannot find Qt**: Verificar caminho em `CMAKE_PREFIX_PATH`
- **Code signature issues**: Executar `codesign -s - ./app.app`

### Linux
- **libGL.so not found**: `sudo apt-get install libgl1-mesa-dev`
- **XCB platform plugin**: Instalar `sudo apt-get install libxcb-xinerama0 libxcb-icccm4`

## CI/CD Workflow

O projeto usa **GitHub Actions** para CI/CD automatizado:

- ✅ **Windows**: Compila e testa automaticamente
- 🔄 **macOS**: Em progresso
- 🔄 **Linux**: Em progresso

Veja `.github/workflows/build.yml` para detalhes.

## Output

Os executáveis compilados estarão em:
- Windows: `build\*.exe`
- macOS: `build\*.app`
- Linux: `build\*` (executáveis)

