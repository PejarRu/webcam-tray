#!/bin/bash

# VirtualCam Service Setup - Auto-detect hardware and configure service
# Supports Intel IPU6 cameras and standard USB webcams

set -e

echo "=== VirtualCam Service Setup ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect camera type
detect_camera() {
    echo "🔍 Detectando cámara..."
    
    # Check for Intel IPU6 camera
    if lspci | grep -qi "Imaging Signal Processor"; then
        if v4l2-ctl --list-devices 2>/dev/null | grep -qi "ov02c10"; then
            echo -e "${GREEN}✓${NC} Intel IPU6 detectado (OmniVision ov02c10-uf)"
            CAMERA_TYPE="ipu6"
            CAMERA_SOURCE="icamerasrc device-name=ov02c10-uf io-mode=userptr buffer-count=3"
            return 0
        fi
    fi
    
    # Check for standard USB webcam
    if v4l2-ctl --list-devices 2>/dev/null | grep -qi "usb"; then
        echo -e "${GREEN}✓${NC} Webcam USB detectada"
        CAMERA_TYPE="usb"
        CAMERA_SOURCE="v4l2src device=/dev/video0"
        return 0
    fi
    
    echo -e "${YELLOW}⚠${NC} No se detectó cámara automáticamente"
    echo "Opciones:"
    echo "  1) Intel IPU6 (icamerasrc)"
    echo "  2) Webcam USB (v4l2src)"
    read -p "Selecciona tipo de cámara [1-2]: " choice
    
    case $choice in
        1)
            CAMERA_TYPE="ipu6"
            CAMERA_SOURCE="icamerasrc device-name=ov02c10-uf io-mode=userptr buffer-count=3"
            ;;
        2)
            CAMERA_TYPE="usb"
            CAMERA_SOURCE="v4l2src device=/dev/video0"
            ;;
        *)
            echo -e "${RED}✗${NC} Selección inválida"
            exit 1
            ;;
    esac
}

# Detect v4l2loopback device
detect_loopback() {
    echo "🔍 Detectando dispositivo v4l2loopback..."
    
    # Check if v4l2loopback is loaded
    if ! lsmod | grep -q v4l2loopback; then
        echo -e "${YELLOW}⚠${NC} Módulo v4l2loopback no cargado"
        echo "Intentando cargar módulo..."
        if sudo modprobe v4l2loopback devices=1 video_nr=48 card_label="VirtualCam" exclusive_caps=1; then
            echo -e "${GREEN}✓${NC} Módulo cargado"
        else
            echo -e "${RED}✗${NC} Error cargando módulo. Instala: v4l2loopback-dkms"
            exit 1
        fi
    fi
    
    # Find loopback device
    LOOPBACK_DEV=$(v4l2-ctl --list-devices 2>/dev/null | grep -A1 "v4l2loopback\|VirtualCam" | tail -n1 | tr -d '\t' || echo "/dev/video48")
    
    if [ -e "$LOOPBACK_DEV" ]; then
        echo -e "${GREEN}✓${NC} Dispositivo loopback: $LOOPBACK_DEV"
    else
        echo -e "${YELLOW}⚠${NC} Dispositivo $LOOPBACK_DEV no existe, usando /dev/video48"
        LOOPBACK_DEV="/dev/video48"
    fi
}

# Detect optimal resolution and FPS
detect_capabilities() {
    echo "🔍 Detectando capacidades de cámara..."
    
    if [ "$CAMERA_TYPE" = "ipu6" ]; then
        # Intel IPU6 common resolutions
        WIDTH=1280
        HEIGHT=720
        FPS=30
    else
        # Try to get best resolution from USB camera
        if command -v v4l2-ctl &> /dev/null; then
            # Get highest resolution (this is simplified)
            WIDTH=1280
            HEIGHT=720
            FPS=30
        else
            WIDTH=640
            HEIGHT=480
            FPS=30
        fi
    fi
    
    echo -e "${GREEN}✓${NC} Resolución: ${WIDTH}x${HEIGHT}@${FPS}fps"
}

# Generate systemd service file
generate_service() {
    echo "📝 Generando archivo de servicio..."
    
    SERVICE_FILE="$HOME/.config/systemd/user/virtualcam.service"
    mkdir -p "$HOME/.config/systemd/user/"
    
    # Build GStreamer pipeline based on camera type
    if [ "$CAMERA_TYPE" = "ipu6" ]; then
        PIPELINE="$CAMERA_SOURCE \\
  ! video/x-raw,format=NV12,width=$WIDTH,height=$HEIGHT,framerate=$FPS/1 \\
  ! videoconvert ! video/x-raw,format=YUY2 \\
  ! queue leaky=2 max-size-buffers=8 \\
  ! identity drop-allocation=true \\
  ! v4l2sink device=$LOOPBACK_DEV io-mode=mmap sync=false qos=false async=false"
    else
        PIPELINE="$CAMERA_SOURCE \\
  ! video/x-raw,width=$WIDTH,height=$HEIGHT,framerate=$FPS/1 \\
  ! videoconvert ! video/x-raw,format=YUY2 \\
  ! queue leaky=2 max-size-buffers=8 \\
  ! v4l2sink device=$LOOPBACK_DEV sync=false"
    fi
    
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=VirtualCam ($CAMERA_TYPE -> v4l2loopback)
After=default.target
ConditionPathExists=$LOOPBACK_DEV

[Service]
Type=simple
Environment=GST_DEBUG=2
# Ensure no process is using the physical camera
ExecStartPre=/usr/bin/bash -c 'fuser -k /dev/video0 2>/dev/null || true'
ExecStart=/usr/bin/gst-launch-1.0 -v \\
  $PIPELINE
Restart=always
RestartSec=3
StartLimitBurst=3
StartLimitIntervalSec=300

[Install]
WantedBy=default.target
EOF

    echo -e "${GREEN}✓${NC} Servicio generado: $SERVICE_FILE"
}

# Configure v4l2loopback to load on boot
configure_autoload() {
    echo "🔧 ¿Configurar v4l2loopback para cargar al inicio? [y/N]"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        MODPROBE_CONF="/etc/modprobe.d/v4l2loopback.conf"
        MODULES_LOAD="/etc/modules-load.d/v4l2loopback.conf"
        
        echo "Se requiere sudo para configurar módulos del kernel..."
        
        # Create modprobe config
        echo "options v4l2loopback devices=1 video_nr=48 card_label=\"VirtualCam\" exclusive_caps=1" | sudo tee "$MODPROBE_CONF" > /dev/null
        
        # Load on boot
        echo "v4l2loopback" | sudo tee "$MODULES_LOAD" > /dev/null
        
        echo -e "${GREEN}✓${NC} v4l2loopback se cargará automáticamente al inicio"
    fi
}

# Enable and start service
enable_service() {
    echo ""
    echo "🚀 ¿Habilitar y iniciar el servicio ahora? [y/N]"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        systemctl --user daemon-reload
        systemctl --user enable virtualcam.service
        systemctl --user start virtualcam.service
        
        sleep 2
        
        if systemctl --user is-active --quiet virtualcam.service; then
            echo -e "${GREEN}✓${NC} Servicio activo"
            echo ""
            echo "Prueba con: ffplay $LOOPBACK_DEV"
        else
            echo -e "${RED}✗${NC} Error iniciando servicio"
            echo "Ver logs: journalctl --user -u virtualcam.service -n 50"
        fi
    else
        echo ""
        echo "Para habilitar manualmente:"
        echo "  systemctl --user enable virtualcam.service"
        echo "  systemctl --user start virtualcam.service"
    fi
}

# Main execution
main() {
    # Check dependencies
    MISSING_DEPS=()
    command -v v4l2-ctl &> /dev/null || MISSING_DEPS+=("v4l2-utils")
    command -v gst-launch-1.0 &> /dev/null || MISSING_DEPS+=("gstreamer")
    command -v lsmod &> /dev/null || MISSING_DEPS+=("kmod")
    
    if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
        echo -e "${RED}✗${NC} Faltan dependencias: ${MISSING_DEPS[*]}"
        exit 1
    fi
    
    detect_camera
    detect_loopback
    detect_capabilities
    generate_service
    configure_autoload
    enable_service
    
    echo ""
    echo -e "${GREEN}✅ Setup completado${NC}"
    echo ""
    echo "Siguiente paso: ejecutar 'webcam-tray' para control gráfico"
}

main
