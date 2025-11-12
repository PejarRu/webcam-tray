#!/bin/bash

set -e

echo "=== VirtualCam Tray - Instalador ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    else
        DISTRO="unknown"
    fi
}

# Check dependencies
check_deps() {
    echo "🔍 Verificando dependencias..."
    
    MISSING_DEPS=()
    MISSING_PKGS=()
    
    # GUI dependencies
    if ! command -v yad &> /dev/null; then
        MISSING_DEPS+=("yad")
        MISSING_PKGS+=("yad")
    fi
    
    if ! command -v zenity &> /dev/null; then
        MISSING_DEPS+=("zenity")
        MISSING_PKGS+=("zenity")
    fi
    
    if ! command -v notify-send &> /dev/null; then
        MISSING_DEPS+=("notify-send")
        case $DISTRO in
            arch|manjaro)
                MISSING_PKGS+=("libnotify")
                ;;
            debian|ubuntu)
                MISSING_PKGS+=("libnotify-bin")
                ;;
            fedora|rhel|centos)
                MISSING_PKGS+=("libnotify")
                ;;
        esac
    fi
    
    # System dependencies
    if ! command -v systemctl &> /dev/null; then
        echo -e "${RED}✗${NC} systemd no detectado (requerido)"
        exit 1
    fi
    
    if ! command -v gst-launch-1.0 &> /dev/null; then
        MISSING_DEPS+=("gst-launch-1.0")
        case $DISTRO in
            arch|manjaro)
                MISSING_PKGS+=("gstreamer")
                ;;
            debian|ubuntu)
                MISSING_PKGS+=("gstreamer1.0-tools")
                ;;
            fedora|rhel|centos)
                MISSING_PKGS+=("gstreamer1-plugins-base-tools")
                ;;
        esac
    fi
    
    if ! command -v v4l2-ctl &> /dev/null; then
        MISSING_DEPS+=("v4l2-ctl")
        MISSING_PKGS+=("v4l2-utils")
    fi
    
    # Check v4l2loopback kernel module
    if ! lsmod | grep -q v4l2loopback; then
        echo -e "${YELLOW}⚠${NC} Módulo v4l2loopback no cargado"
        MISSING_DEPS+=("v4l2loopback")
        case $DISTRO in
            arch|manjaro)
                MISSING_PKGS+=("v4l2loopback-dkms")
                ;;
            debian|ubuntu)
                MISSING_PKGS+=("v4l2loopback-dkms")
                ;;
            fedora|rhel|centos)
                MISSING_PKGS+=("v4l2loopback")
                ;;
        esac
    fi
    
    # Check for Intel IPU6 if needed
    if lspci | grep -qi "Imaging Signal Processor"; then
        if ! gst-inspect-1.0 icamerasrc &> /dev/null; then
            echo -e "${YELLOW}⚠${NC} Plugin icamerasrc no detectado (requerido para Intel IPU6)"
            MISSING_DEPS+=("icamerasrc")
            case $DISTRO in
                arch|manjaro)
                    MISSING_PKGS+=("ipu6-camera-hal" "gst-plugin-icamerasrc")
                    echo -e "${YELLOW}  Instalar desde AUR: yay -S ipu6-camera-hal gst-plugin-icamerasrc${NC}"
                    ;;
            esac
        fi
    fi
    
    if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
        echo -e "${RED}✗${NC} Faltan dependencias: ${MISSING_DEPS[*]}"
        echo ""
        echo "Comando de instalación según tu distribución:"
        echo ""
        
        case $DISTRO in
            arch|manjaro)
                echo "  sudo pacman -S ${MISSING_PKGS[*]}"
                if [[ " ${MISSING_DEPS[@]} " =~ " icamerasrc " ]]; then
                    echo "  yay -S ipu6-camera-hal gst-plugin-icamerasrc"
                fi
                ;;
            debian|ubuntu)
                echo "  sudo apt update"
                echo "  sudo apt install ${MISSING_PKGS[*]}"
                ;;
            fedora)
                echo "  sudo dnf install ${MISSING_PKGS[*]}"
                ;;
            *)
                echo "  Instalar manualmente: ${MISSING_PKGS[*]}"
                ;;
        esac
        
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Todas las dependencias instaladas"
}

# Install webcam-tray
install_binary() {
    echo "📦 Instalando webcam-tray..."
    
    mkdir -p ~/.local/bin
    cp webcam-tray ~/.local/bin/
    chmod +x ~/.local/bin/webcam-tray
    
    echo -e "${GREEN}✓${NC} Instalado en ~/.local/bin/webcam-tray"
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo -e "${YELLOW}⚠${NC} ~/.local/bin no está en tu PATH"
        echo ""
        echo "Agrega esto a tu ~/.bashrc o ~/.zshrc:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

# Offer to run setup
offer_setup() {
    echo ""
    echo "🚀 ¿Ejecutar setup automático del servicio? [y/N]"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if [ -f "./setup-service.sh" ]; then
            ./setup-service.sh
        else
            echo -e "${YELLOW}⚠${NC} setup-service.sh no encontrado"
            echo "Ejecuta manualmente: ./setup-service.sh"
        fi
    else
        echo ""
        echo "Para configurar el servicio más tarde, ejecuta:"
        echo "  ./setup-service.sh"
        echo ""
        echo "O configuración manual:"
        echo "  1. Copia virtualcam.service.example a ~/.config/systemd/user/virtualcam.service"
        echo "  2. Edita el archivo según tu hardware"
        echo "  3. systemctl --user enable virtualcam.service"
        echo "  4. systemctl --user start virtualcam.service"
    fi
}

# Main
main() {
    detect_distro
    echo "Sistema detectado: $DISTRO"
    echo ""
    
    check_deps
    install_binary
    offer_setup
    
    echo ""
    echo -e "${GREEN}✅ Instalación completada${NC}"
    echo ""
    echo "Para iniciar el tray:"
    echo "  webcam-tray"
    echo ""
    echo "Para desinstalar en el futuro:"
    echo "  ./uninstall.sh"
}

main
