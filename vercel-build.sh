#!/bin/bash
set -e

echo "=== Comprobando Flutter SDK ==="
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter SDK (canal stable)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
else
  echo "Flutter ya se encuentra descargado."
fi

export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Verificando versión de Flutter ==="
flutter --version

echo "=== Descargando dependencias ==="
flutter pub get

echo "=== Compilando aplicación para Web (Release) ==="
flutter build web --release --no-wasm-dry-run

echo "=== Compilación completada con éxito ==="
