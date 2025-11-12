# Maintainer: PejarRu <https://github.com/PejarRu>
pkgname=webcam-tray
pkgver=1.1.0
pkgrel=1
pkgdesc="System tray icon for controlling VirtualCam service on Linux (Intel IPU6 cameras)"
arch=('any')
url="https://github.com/PejarRu/webcam-tray"
license=('MIT')
depends=('yad' 'zenity' 'libnotify' 'gstreamer' 'v4l2-utils' 'systemd')
optdepends=(
    'v4l2loopback-dkms: Virtual camera device support'
    'ipu6-camera-hal: Intel IPU6 camera support'
    'gst-plugin-icamerasrc: GStreamer plugin for Intel IPU6'
)
source=("$pkgname-$pkgver.tar.gz::https://github.com/PejarRu/$pkgname/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "$srcdir/$pkgname-$pkgver"
    
    # Install main binary
    install -Dm755 webcam-tray "$pkgdir/usr/bin/webcam-tray"
    
    # Install helper scripts
    install -Dm755 setup-service.sh "$pkgdir/usr/bin/webcam-tray-setup"
    install -Dm755 configure-gui.sh "$pkgdir/usr/bin/webcam-tray-config"
    install -Dm755 install.sh "$pkgdir/usr/share/$pkgname/install.sh"
    install -Dm755 uninstall.sh "$pkgdir/usr/share/$pkgname/uninstall.sh"
    
    # Install service template
    install -Dm644 virtualcam.service.example "$pkgdir/usr/share/$pkgname/virtualcam.service.example"
    
    # Install documentation
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    
    # Install desktop entry for autostart (optional)
    install -Dm644 - "$pkgdir/usr/share/applications/webcam-tray.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=VirtualCam Tray
Comment=Control del servicio VirtualCam
Exec=/usr/bin/webcam-tray
Icon=camera-web
Terminal=false
Categories=Utility;System;
StartupNotify=false
EOF
}
