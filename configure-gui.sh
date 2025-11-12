#!/bin/bash

# VirtualCam Tray - GUI Configuration Tool
# Interactive setup using yad dialogs

set -e

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/webcam-tray"
CONFIG_FILE="$CONFIG_DIR/config"
SERVICE_FILE="$HOME/.config/systemd/user/virtualcam.service"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load existing config
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Defaults
    UPDATE_INTERVAL="${UPDATE_INTERVAL:-2}"
    SERVICE_NAME="${SERVICE_NAME:-virtualcam.service}"
    ICON="${ICON:-camera-web}"
}

# Main configuration dialog
main_config_dialog() {
    load_config
    
    RESULT=$(yad --form --title="VirtualCam Tray - Configuración" \
        --width=500 --height=300 \
        --text="<b>Configuración de VirtualCam Tray</b>" \
        --field="Intervalo de actualización (segundos):NUM" "$UPDATE_INTERVAL" \
        --field="Nombre del servicio:" "$SERVICE_NAME" \
        --field="Icono:" "$ICON" \
        --field="Autostart en login:CHK" "FALSE" \
        --button="Cancelar:1" \
        --button="Configurar Servicio:2" \
        --button="Guardar:0")
    
    RET=$?
    
    case $RET in
        0)  # Save
            save_config "$RESULT"
            yad --info --text="Configuración guardada en:\n$CONFIG_FILE" --width=400
            ;;
        2)  # Configure Service
            if [ -f "./setup-service.sh" ]; then
                ./setup-service.sh
            else
                yad --error --text="setup-service.sh no encontrado" --width=400
            fi
            ;;
        *)  # Cancel
            exit 0
            ;;
    esac
}

# Save configuration
save_config() {
    local data="$1"
    
    # Parse yad output
    IFS='|' read -r interval service icon autostart <<< "$data"
    
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_FILE" <<EOF
# VirtualCam Tray Configuration
# Generated: $(date)

# Update interval in seconds
UPDATE_INTERVAL=$interval

# Service name
SERVICE_NAME="$service"

# Icon name (from icon theme)
ICON="$icon"
EOF

    # Setup autostart if requested
    if [ "$autostart" = "TRUE" ]; then
        setup_autostart
    fi
}

# Setup autostart
setup_autostart() {
    AUTOSTART_DIR="$HOME/.config/autostart"
    AUTOSTART_FILE="$AUTOSTART_DIR/webcam-tray.desktop"
    
    mkdir -p "$AUTOSTART_DIR"
    
    cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=VirtualCam Tray
Comment=Control del servicio VirtualCam
Exec=$HOME/.local/bin/webcam-tray
Icon=camera-web
Terminal=false
Categories=Utility;
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF

    echo -e "${GREEN}✓${NC} Autostart configurado"
}

# Advanced service configuration
service_config_dialog() {
    if [ ! -f "$SERVICE_FILE" ]; then
        yad --error --text="Servicio no configurado.\nEjecuta primero: ./setup-service.sh" --width=400
        return
    fi
    
    # Read current service settings
    CURRENT_DEVICE=$(grep "device=" "$SERVICE_FILE" | head -1 | sed 's/.*device=\([^ ]*\).*/\1/' || echo "/dev/video48")
    CURRENT_RESOLUTION=$(grep "width=" "$SERVICE_FILE" | sed 's/.*width=\([0-9]*\).*height=\([0-9]*\).*/\1x\2/' || echo "1280x720")
    
    RESULT=$(yad --form --title="Configuración del Servicio" \
        --width=500 --height=400 \
        --text="<b>Configuración avanzada del servicio virtualcam</b>" \
        --field="Dispositivo de salida:" "$CURRENT_DEVICE" \
        --field="Resolución:CB" "1920x1080!1280x720!640x480" \
        --field="FPS:NUM" "30" \
        --field="Habilitar servicio:CHK" "TRUE" \
        --field="Iniciar ahora:CHK" "FALSE" \
        --button="gtk-cancel:1" \
        --button="gtk-apply:0")
    
    if [ $? -eq 0 ]; then
        yad --info --text="Para cambios avanzados, edita:\n$SERVICE_FILE" --width=400
    fi
}

# Main menu
main_menu() {
    CHOICE=$(yad --list --title="VirtualCam Tray - Configuración" \
        --width=400 --height=300 \
        --text="<b>¿Qué deseas configurar?</b>" \
        --column="Opción" \
        --column="Descripción" \
        "1" "Configuración básica" \
        "2" "Setup del servicio (hardware)" \
        "3" "Configurar autostart" \
        "4" "Ver configuración actual" \
        --button="Salir:1" \
        --button="Seleccionar:0")
    
    RET=$?
    if [ $RET -ne 0 ]; then
        exit 0
    fi
    
    case "${CHOICE%%|*}" in
        1)
            main_config_dialog
            ;;
        2)
            if [ -f "./setup-service.sh" ]; then
                x-terminal-emulator -e "./setup-service.sh" || xterm -e "./setup-service.sh"
            else
                yad --error --text="setup-service.sh no encontrado" --width=400
            fi
            ;;
        3)
            setup_autostart
            yad --info --text="Autostart configurado" --width=400
            ;;
        4)
            load_config
            yad --text-info --title="Configuración Actual" \
                --width=500 --height=400 \
                --filename="$CONFIG_FILE" || \
            yad --info --text="No hay configuración guardada aún" --width=400
            ;;
    esac
}

# Check if yad is available
if ! command -v yad &> /dev/null; then
    echo "Error: yad no está instalado"
    echo "Instalar: sudo pacman -S yad (Arch) o sudo apt install yad (Ubuntu)"
    exit 1
fi

# Run main menu
main_menu
