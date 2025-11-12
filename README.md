# VirtualCam Tray

Sistema de control gráfico para gestionar servicios de cámara virtual en Linux mediante un icono en la bandeja del sistema (system tray).

![Platform](https://img.shields.io/badge/platform-linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🎯 Características

- ✅ Icono permanente en system tray
- ✅ Control fácil del servicio virtualcam (iniciar/detener)
- ✅ Notificaciones de estado
- ✅ Visualización de logs en tiempo real
- ✅ Actualización automática del estado cada 2 segundos
- ✅ Autostart en login
- ✅ Mismo icono independiente del estado (solo cambia el tooltip)

## 📋 Requisitos

### Obligatorios
- **Linux** con systemd
- `yad` - Diálogos gráficos
- `zenity` - Visualización de logs
- `notify-send` (libnotify) - Notificaciones
- `systemctl` - Control de servicios

### Para Samsung Galaxy Book4 Pro (y laptops con Intel IPU6)
- `gstreamer` con `icamerasrc`
- `v4l2loopback-dkms`
- `ipu6-camera-hal`
- Linux kernel 6.x+

## 🚀 Instalación

### 1. Instalar dependencias

#### Arch Linux
```bash
sudo pacman -S yad zenity libnotify
# Para Intel IPU6 cámaras:
yay -S v4l2loopback-dkms ipu6-camera-hal gst-plugin-icamerasrc
```

#### Ubuntu/Debian
```bash
sudo apt install yad zenity libnotify-bin
# Para v4l2loopback:
sudo apt install v4l2loopback-dkms
```

#### Fedora
```bash
sudo dnf install yad zenity libnotify
sudo dnf install v4l2loopback
```

### 2. Instalar webcam-tray

```bash
# Clonar repositorio
git clone https://github.com/TU_USUARIO/webcam-tray.git
cd webcam-tray

# Ejecutar instalador
chmod +x install.sh
./install.sh
```

O manualmente:
```bash
mkdir -p ~/.local/bin
cp webcam-tray ~/.local/bin/
chmod +x ~/.local/bin/webcam-tray
```

### 3. Configurar el servicio systemd

```bash
mkdir -p ~/.config/systemd/user/
cp virtualcam.service.example ~/.config/systemd/user/virtualcam.service

# IMPORTANTE: Editar según tu hardware
nano ~/.config/systemd/user/virtualcam.service
```

### 4. Habilitar e iniciar

```bash
systemctl --user enable virtualcam.service
systemctl --user start virtualcam.service
webcam-tray
```

## 📖 Uso

### Comandos
```bash
webcam-tray         # Iniciar tray icon
webcam-tray start   # Iniciar servicio
webcam-tray stop    # Detener servicio
webcam-tray status  # Mostrar estado
webcam-tray logs    # Ver logs
```

### Desde el tray
- **Click derecho** → Menú
- El icono permanece siempre visible
- Solo el tooltip cambia (✓ Activo / ✗ Inactivo)

## 🖥️ Compatibilidad

### SO
- ✅ Arch Linux
- ⚠️ Ubuntu/Debian (requiere configuración adicional)
- ⚠️ Fedora (requiere configuración adicional)
- ❌ Windows/macOS (no compatible)

### Hardware
- ✅ Samsung Galaxy Book4 Pro (Intel IPU6)
- ⚠️ Webcams USB (cambiar `icamerasrc` por `v4l2src`)

## 📝 Licencia

MIT License

## 👤 Autor

Creado para Samsung Galaxy Book4 Pro en Arch Linux
