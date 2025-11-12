#!/bin/bash

# VirtualCam Tray - Desinstalador
# Elimina la aplicación y limpia la configuración

set -e

echo "=== VirtualCam Tray - Desinstalador ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SERVICE_NAME="virtualcam.service"
SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME"
CONFIG_DIR="$HOME/.config/webcam-tray"
AUTOSTART_FILE="$HOME/.config/autostart/webcam-tray.desktop"
BINARY_FILE="$HOME/.local/bin/webcam-tray"

# Confirm uninstall
confirm_uninstall() {
    echo -e "${YELLOW}⚠${NC}  Esto eliminará:"
    echo "  • Binario: $BINARY_FILE"
    echo "  • Configuración: $CONFIG_DIR"
    echo "  • Servicio systemd: $SERVICE_FILE"
    echo "  • Autostart: $AUTOSTART_FILE"
    echo ""
    echo -e "${BLUE}ℹ${NC}  NO se eliminarán:"
    echo "  • Dependencias instaladas (yad, zenity, gstreamer, etc.)"
    echo "  • Módulo del kernel v4l2loopback"
    echo ""
    
    read -p "¿Continuar con la desinstalación? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Desinstalación cancelada."
        exit 0
    fi
}

# Stop and disable service
stop_service() {
    echo ""
    echo "🛑 Deteniendo servicio..."
    
    if systemctl --user is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl --user stop "$SERVICE_NAME"
        echo -e "${GREEN}✓${NC} Servicio detenido"
    else
        echo -e "${YELLOW}⚠${NC} Servicio no está en ejecución"
    fi
    
    if systemctl --user is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl --user disable "$SERVICE_NAME"
        echo -e "${GREEN}✓${NC} Servicio deshabilitado"
    else
        echo -e "${YELLOW}⚠${NC} Servicio no estaba habilitado"
    fi
}

# Remove files
remove_files() {
    echo ""
    echo "🗑️  Eliminando archivos..."
    
    # Remove binary
    if [ -f "$BINARY_FILE" ]; then
        rm -f "$BINARY_FILE"
        echo -e "${GREEN}✓${NC} Eliminado: $BINARY_FILE"
    else
        echo -e "${YELLOW}⚠${NC} No encontrado: $BINARY_FILE"
    fi
    
    # Remove configuration
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        echo -e "${GREEN}✓${NC} Eliminado: $CONFIG_DIR"
    else
        echo -e "${YELLOW}⚠${NC} No encontrado: $CONFIG_DIR"
    fi
    
    # Remove autostart
    if [ -f "$AUTOSTART_FILE" ]; then
        rm -f "$AUTOSTART_FILE"
        echo -e "${GREEN}✓${NC} Eliminado: $AUTOSTART_FILE"
    else
        echo -e "${YELLOW}⚠${NC} No encontrado: $AUTOSTART_FILE"
    fi
    
    # Remove service file
    if [ -f "$SERVICE_FILE" ]; then
        rm -f "$SERVICE_FILE"
        echo -e "${GREEN}✓${NC} Eliminado: $SERVICE_FILE"
    else
        echo -e "${YELLOW}⚠${NC} No encontrado: $SERVICE_FILE"
    fi
}

# Reload systemd
reload_systemd() {
    echo ""
    echo "🔄 Recargando systemd..."
    systemctl --user daemon-reload
    echo -e "${GREEN}✓${NC} Systemd recargado"
}

# Optional: Remove v4l2loopback module
remove_kernel_module() {
    echo ""
    echo -e "${BLUE}ℹ${NC}  El módulo v4l2loopback permite usar cámaras virtuales"
    read -p "¿Descargar módulo v4l2loopback del kernel? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if lsmod | grep -q v4l2loopback; then
            echo "Descargando módulo..."
            if sudo modprobe -r v4l2loopback 2>/dev/null; then
                echo -e "${GREEN}✓${NC} Módulo v4l2loopback descargado"
            else
                echo -e "${YELLOW}⚠${NC} No se pudo descargar el módulo (puede estar en uso)"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Módulo v4l2loopback no está cargado"
        fi
        
        # Remove auto-load config
        if [ -f /etc/modules-load.d/v4l2loopback.conf ]; then
            read -p "¿Eliminar configuración de carga automática? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo rm -f /etc/modules-load.d/v4l2loopback.conf
                echo -e "${GREEN}✓${NC} Configuración de carga automática eliminada"
            fi
        fi
    else
        echo "Módulo v4l2loopback conservado (puede usarlo otro software)"
    fi
}

# Optional: Remove dependencies
remove_dependencies() {
    echo ""
    echo -e "${BLUE}ℹ${NC}  Las dependencias (yad, zenity, gstreamer, etc.) pueden ser usadas por otros programas"
    read -p "¿Desinstalar dependencias de VirtualCam Tray? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Detect distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        else
            DISTRO="unknown"
        fi
        
        echo ""
        echo "Comandos sugeridos para desinstalar dependencias:"
        echo ""
        
        case $DISTRO in
            arch|manjaro)
                echo "  sudo pacman -R yad zenity libnotify v4l2-utils"
                echo "  sudo pacman -R v4l2loopback-dkms  # Opcional"
                echo ""
                echo "Si usas Intel IPU6:"
                echo "  yay -R ipu6-camera-hal gst-plugin-icamerasrc"
                ;;
            debian|ubuntu)
                echo "  sudo apt remove yad zenity libnotify-bin v4l2-utils"
                echo "  sudo apt remove v4l2loopback-dkms  # Opcional"
                ;;
            fedora|rhel|centos)
                echo "  sudo dnf remove yad zenity libnotify v4l2-utils"
                echo "  sudo dnf remove v4l2loopback  # Opcional"
                ;;
            *)
                echo "  Desinstala manualmente: yad, zenity, libnotify, v4l2-utils"
                ;;
        esac
        
        echo ""
        echo "⚠️  Ejecuta estos comandos SOLO si estás seguro de que ningún otro programa los usa"
    fi
}

# Main
main() {
    confirm_uninstall
    stop_service
    remove_files
    reload_systemd
    remove_kernel_module
    remove_dependencies
    
    echo ""
    echo -e "${GREEN}✅ Desinstalación completada${NC}"
    echo ""
    echo "VirtualCam Tray ha sido eliminado de tu sistema."
    echo ""
    echo "Si deseas reinstalar en el futuro:"
    echo "  ./install.sh"
    echo ""
}

main
