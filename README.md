# VirtualCam Tray

Sistema de control gráfico para gestionar servicios de cámara virtual en Linux mediante un icono en la bandeja del sistema (system tray).

![Platform](https://img.shields.io/badge/platform-linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.1.0-orange)

## 🎯 Características

### Funcionalidad Principal
- ✅ **Icono permanente en system tray** con actualización de estado
- ✅ **Control fácil del servicio** virtualcam (iniciar/detener/toggle)
- ✅ **Notificaciones de estado** con notify-send
- ✅ **Visualización de logs** en tiempo real con zenity
- ✅ **Autostart en login** configurable
- ✅ **Mismo icono** independiente del estado (solo cambia el tooltip)

### Mejoras v1.1.0
- 🆕 **Setup automático** con detección de hardware
- 🆕 **Soporte multi-distro** (Arch, Ubuntu, Debian, Fedora)
- 🆕 **Configuración GUI** con yad dialogs
- 🆕 **XDG Base Directory** compliance
- 🆕 **Logging estructurado** con systemd journal
- 🆕 **Validación de PID** para seguridad
- 🆕 **Archivo de configuración** en `~/.config/webcam-tray/config`
- 🆕 **Detección automática** de cámara Intel IPU6 o USB
- 🆕 **PKGBUILD para AUR** (Arch User Repository)
- 🆕 **CI/CD con GitHub Actions**
- 🆕 **Tests automatizados** con bats
- 🆕 **Manpage incluida**

### Mejoras v1.2.0
- 🆕 **Autostart en login** - Habilitar/deshabilitar desde menú del tray
- 🆕 **Logs estructurados en JSON** - Logging con timestamps y event types
- 🆕 **Suite de tests completa** - Smoke, Chaos, Performance tests
- 🆕 **Integration tests en CI** - Tests en Arch, Ubuntu y Fedora

## 📋 Requisitos

### Obligatorios
- **Linux** con systemd
- `yad` - Diálogos gráficos
- `zenity` - Visualización de logs
- `notify-send` (libnotify) - Notificaciones
- `systemctl` - Control de servicios
- `gstreamer` - Pipeline de video
- `v4l2-utils` - Herramientas v4l2

### Recomendados
- `v4l2loopback-dkms` - Dispositivo de cámara virtual
- `bats` - Para ejecutar tests (opcional)

### Para Samsung Galaxy Book4 Pro (y laptops con Intel IPU6)
- `ipu6-camera-hal` - HAL para Intel IPU6
- `gst-plugin-icamerasrc` - Plugin GStreamer para IPU6
- Linux kernel 6.x+

## 🚀 Instalación

### Opción 1: Instalación Rápida (Recomendado)

```bash
# Clonar repositorio
git clone https://github.com/PejarRu/webcam-tray.git
cd webcam-tray

# Ejecutar instalador (verifica dependencias y configura todo)
chmod +x install.sh
./install.sh
```

El instalador:
1. Detecta tu distribución
2. Verifica todas las dependencias
3. Instala `webcam-tray` en `~/.local/bin/`
4. Ofrece ejecutar `setup-service.sh` automáticamente

### Opción 2: Arch Linux (AUR)

```bash
yay -S webcam-tray
# o
paru -S webcam-tray
```

### Opción 3: Instalación Manual

#### 1. Instalar dependencias

**Arch Linux**
```bash
sudo pacman -S yad zenity libnotify gstreamer v4l2-utils
# Para Intel IPU6 cámaras:
yay -S v4l2loopback-dkms ipu6-camera-hal gst-plugin-icamerasrc
```

**Ubuntu/Debian**
```bash
sudo apt install yad zenity libnotify-bin gstreamer1.0-tools v4l2-utils
# Para v4l2loopback:
sudo apt install v4l2loopback-dkms
```

**Fedora**
```bash
sudo dnf install yad zenity libnotify gstreamer1-plugins-base-tools v4l2-utils
sudo dnf install v4l2loopback
```

#### 2. Instalar webcam-tray

```bash
mkdir -p ~/.local/bin
cp webcam-tray ~/.local/bin/
chmod +x ~/.local/bin/webcam-tray

# Asegúrate de que ~/.local/bin está en tu PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc  # o ~/.zshrc
```

#### 3. Setup del servicio (con detección automática)

```bash
./setup-service.sh
```

Este script:
- ✅ Detecta automáticamente tu cámara (Intel IPU6 o USB)
- ✅ Encuentra el dispositivo v4l2loopback
- ✅ Genera el servicio systemd optimizado
- ✅ Configura autoload del módulo v4l2loopback
- ✅ Habilita e inicia el servicio

#### 4. Iniciar el tray

```bash
webcam-tray
```

## �️ Desinstalación

### Desinstalación Rápida (Recomendado)

```bash
# Ejecutar desinstalador
chmod +x uninstall.sh
./uninstall.sh
```

El desinstalador:
1. Detiene y deshabilita el servicio virtualcam
2. Elimina el binario de `~/.local/bin/webcam-tray`
3. Elimina configuración de `~/.config/webcam-tray/`
4. Elimina autostart de `~/.config/autostart/`
5. Elimina el servicio systemd
6. Opcionalmente descarga el módulo v4l2loopback
7. Opcionalmente muestra comandos para desinstalar dependencias

**Nota:** Las dependencias (yad, zenity, gstreamer, etc.) NO se eliminan automáticamente porque pueden ser usadas por otros programas.

### Desinstalación desde AUR

```bash
yay -R webcam-tray
# o
paru -R webcam-tray
```

### Desinstalación Manual

```bash
# 1. Detener y deshabilitar servicio
systemctl --user stop virtualcam.service
systemctl --user disable virtualcam.service

# 2. Eliminar archivos
rm ~/.local/bin/webcam-tray
rm -rf ~/.config/webcam-tray/
rm ~/.config/autostart/webcam-tray.desktop
rm ~/.config/systemd/user/virtualcam.service

# 3. Recargar systemd
systemctl --user daemon-reload

# 4. (Opcional) Descargar módulo kernel
sudo modprobe -r v4l2loopback

# 5. (Opcional) Desinstalar dependencias
# ARCH
sudo pacman -R yad zenity libnotify v4l2-utils v4l2loopback-dkms

# UBUNTU/DEBIAN
sudo apt remove yad zenity libnotify-bin v4l2-utils v4l2loopback-dkms

# FEDORA
sudo dnf remove yad zenity libnotify v4l2-utils v4l2loopback
```

## �📖 Uso

### Comandos CLI

```bash
webcam-tray           # Iniciar tray icon (default)
webcam-tray start     # Iniciar servicio
webcam-tray stop      # Detener servicio
webcam-tray toggle    # Alternar estado
webcam-tray status    # Mostrar estado
webcam-tray logs      # Ver logs
webcam-tray config    # Abrir configuración
webcam-tray autostart-enable  # Habilitar autostart
webcam-tray autostart-disable # Deshabilitar autostart
webcam-tray --help    # Ayuda
```

### Desde el tray
- **Click derecho** → Menú contextual
  - Iniciar
  - Detener
  - Toggle
  - Estado
  - Ver Logs
  - Configuración
  - **Autostart** (submenu)
    - Habilitar
    - Deshabilitar
    - Estado
  - Salir
- El icono permanece siempre visible
- Solo el tooltip cambia: **"✓ Activo"** / **"✗ Inactivo"**

### Configuración GUI

```bash
./configure-gui.sh
# o (si instalado desde AUR)
webcam-tray-config
```

Permite configurar:
- Intervalo de actualización
- Nombre del servicio
- Icono del tray
- Autostart en login
- Configuración del servicio

## ⚙️ Configuración

### Archivo de configuración

`~/.config/webcam-tray/config`

```bash
# Intervalo de actualización en segundos
UPDATE_INTERVAL=2

# Nombre del servicio systemd
SERVICE_NAME="virtualcam.service"

# Icono del tema del sistema
ICON="camera-web"

# Log format: text or json
LOG_FORMAT=text

# Autostart on login
AUTOSTART=false
```

### Logging

El proyecto soporta dos formatos de logging:

**Formato texto** (default):
```bash
[INFO] Starting virtualcam.service
[ERROR] Service failed
```

**Formato JSON estructurado**:
```bash
# En ~/.config/webcam-tray/config
LOG_FORMAT=json
```

Logs JSON incluyen:
- `timestamp` (ISO 8601)
- `level` (info, error, event)
- `hostname`
- `service` (webcam-tray)
- `msg` (mensaje)
- `event_type` (para eventos)
- Campos adicionales según contexto

**Ver logs**:
```bash
# Logs del tray
journalctl -t webcam-tray -f

# Logs del servicio
journalctl --user -u virtualcam.service -f

# Logs JSON con jq
journalctl -t webcam-tray -o cat | jq '.'
```

### Autostart

Para que el tray se inicie automáticamente:

**Opción 1: Usar configure-gui.sh**
```bash
./configure-gui.sh
# Seleccionar "Configurar autostart"
```

**Opción 2: Manual**
```bash
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/webcam-tray.desktop <<EOF
[Desktop Entry]
Type=Application
Name=VirtualCam Tray
Exec=$HOME/.local/bin/webcam-tray
Icon=camera-web
Terminal=false
Categories=Utility;
EOF
```

## 🖥️ Compatibilidad

### Distribuciones

| SO | Estado | Notas |
|---|---|---|
| ✅ Arch Linux | Completamente soportado | Instalación vía AUR disponible |
| ✅ Manjaro | Completamente soportado | Usar comandos de Arch |
| ✅ Ubuntu/Debian | Soportado | Requiere instalación manual de dependencias |
| ✅ Fedora | Soportado | Requiere instalación manual de dependencias |
| ❌ Windows/macOS | No compatible | Solo Linux con systemd |

### Hardware

| Cámara | Estado | Configuración |
|---|---|---|
| ✅ Intel IPU6 (ov02c10) | Totalmente soportado | Auto-detectado por `setup-service.sh` |
| ✅ Samsung Galaxy Book4 Pro | Totalmente soportado | Configuración optimizada |
| ✅ Webcams USB estándar | Soportado | Auto-detectado, usa v4l2src |
| ⚠️ Otras cámaras Intel | Puede funcionar | Requiere configuración manual |

## 🧪 Testing

El proyecto incluye una suite completa de tests:

### Tests disponibles

1. **Unit Tests** (bats)
   - Tests básicos de funcionalidad
   - Sin dependencias de hardware

2. **Smoke Tests**
   - Verificación rápida con hardware real
   - Instala, configura e inicia el servicio

3. **Chaos Tests**
   - Tests de resiliencia
   - Kill de procesos, remoción de módulos, etc.

4. **Performance Tests**
   - Medición de FPS, latencia, CPU, memoria
   - Sustained load tests

5. **Integration Tests** (CI)
   - Tests automáticos en Arch, Ubuntu, Fedora
   - Ejecutan en cada push/PR

### Ejecutar tests

```bash
# Todos los tests
./tests/run-all.sh

# Tests específicos
./tests/run-all.sh --smoke-only
./tests/run-all.sh --chaos-only
./tests/run-all.sh --performance-only

# Unit tests con bats
bats tests/

# Tests individuales
./tests/smoke-test.sh
./tests/chaos-test.sh
./tests/performance-test.sh
```

### Requisitos para tests

```bash
# Instalar bats (Arch)
sudo pacman -S bats bc v4l2loopback-dkms

# Instalar bats (Ubuntu)
sudo apt install bats bc v4l2loopback-dkms
```

Ver [tests/README.md](tests/README.md) para documentación completa.

## 🔧 Troubleshooting

### El servicio no inicia

```bash
# Ver logs detallados
journalctl --user -u virtualcam.service -n 50

# Verificar que v4l2loopback está cargado
lsmod | grep v4l2loopback

# Cargar módulo manualmente
sudo modprobe v4l2loopback devices=1 video_nr=48 card_label="VirtualCam"
```

### La cámara está ocupada

```bash
# Ver qué proceso usa la cámara
fuser /dev/video0

# El servicio automáticamente mata procesos en ExecStartPre
systemctl --user restart virtualcam.service
```

### El tray no aparece

```bash
# Verificar que yad está instalado
which yad

# Verificar logs del tray
journalctl -t webcam-tray

# Matar instancias previas
pkill -f "yad.*webcam"
```

### Dependencias faltantes

```bash
# Re-ejecutar install.sh para verificar
./install.sh
```

## 🧪 Testing

```bash
# Instalar bats (Arch)
sudo pacman -S bats

# Ejecutar tests
bats tests/

# Ejecutar shellcheck
shellcheck webcam-tray setup-service.sh install.sh configure-gui.sh
```

## � Documentación

### Manpage

```bash
man ./webcam-tray.1
# o (si instalado desde AUR)
man webcam-tray
```

### Estructura del proyecto

```
webcam-tray/
├── webcam-tray              # Script principal del tray
├── setup-service.sh         # Setup automático con detección de hardware
├── install.sh               # Instalador con verificación de dependencias
├── configure-gui.sh         # GUI de configuración
├── virtualcam.service.example  # Template del servicio systemd
├── PKGBUILD                 # Package para Arch Linux (AUR)
├── webcam-tray.1            # Manpage
├── README.md                # Este archivo
├── LICENSE                  # Licencia MIT
├── .github/
│   └── workflows/
│       ├── ci.yml           # Tests automáticos
│       └── release.yml      # Releases automáticos
└── tests/
    ├── test_webcam-tray.bats
    ├── test_install.bats
    └── README.md
```

## 🤝 Contribuir

Las contribuciones son bienvenidas!

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Ejecutar tests antes de commit

```bash
bats tests/
shellcheck webcam-tray setup-service.sh install.sh configure-gui.sh
```

## 📝 Changelog

### v1.2.0 (2025-11-12)
- ✨ Autostart en login (habilitar/deshabilitar desde tray)
- ✨ Logs estructurados en JSON con timestamps
- ✨ Suite completa de tests (smoke, chaos, performance)
- ✨ Integration tests en CI para Arch, Ubuntu, Fedora
- 📚 Documentación extendida de testing

### v1.1.0 (2025-11-12)
- ✨ Setup automático con detección de hardware
- ✨ Soporte multi-distro (Arch, Ubuntu, Debian, Fedora)
- ✨ GUI de configuración con yad
- ✨ XDG Base Directory compliance
- ✨ Logging estructurado con systemd journal
- ✨ Validación de PID para seguridad
- ✨ Archivo de configuración
- ✨ Comando toggle para alternar estado
- ✨ PKGBUILD para AUR
- ✨ GitHub Actions CI/CD
- ✨ Tests automatizados con bats
- ✨ Manpage incluida
- 🐛 Fix: Múltiples instancias del tray
- 🐛 Fix: Archivos temporales en /tmp

### v1.0.0 (2025-11-11)
- 🎉 Release inicial
- ✅ Tray icon básico
- ✅ Control de servicio systemd
- ✅ Visualización de logs
- ✅ Soporte para Intel IPU6

## � Licencia

MIT License - ver [LICENSE](LICENSE) para detalles

Copyright (c) 2025 VirtualCam Tray Contributors

## 👤 Autor

Creado para Samsung Galaxy Book4 Pro con cámara Intel IPU6 en Arch Linux.

**GitHub**: [@PejarRu](https://github.com/PejarRu)

## 🙏 Agradecimientos

- Comunidad de Arch Linux
- Desarrolladores de GStreamer
- Proyecto v4l2loopback
- Intel IPU6 camera drivers team

## 🔗 Links

- **Repositorio**: https://github.com/PejarRu/webcam-tray
- **Issues**: https://github.com/PejarRu/webcam-tray/issues
- **AUR Package**: https://aur.archlinux.org/packages/webcam-tray (próximamente)

---

**⭐ Si este proyecto te ha sido útil, considera darle una estrella en GitHub!**
