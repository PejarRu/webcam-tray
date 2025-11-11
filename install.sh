#!/bin/bash

echo "=== VirtualCam Tray - Instalador ==="
echo ""

# Verificar dependencias
MISSING_DEPS=()
command -v yad &> /dev/null || MISSING_DEPS+=("yad")
command -v zenity &> /dev/null || MISSING_DEPS+=("zenity")
command -v notify-send &> /dev/null || MISSING_DEPS+=("libnotify")

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "❌ Faltan: ${MISSING_DEPS[*]}"
    echo "Arch: sudo pacman -S yad zenity libnotify"
    exit 1
fi

echo "✅ Dependencias OK"

# Instalar
mkdir -p ~/.local/bin
cp webcam-tray ~/.local/bin/
chmod +x ~/.local/bin/webcam-tray
echo "✅ Instalado en ~/.local/bin/webcam-tray"

echo ""
echo "Ejecuta: webcam-tray"
