# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 🆕 **Uninstall script** (`uninstall.sh`)
  - Interactive uninstallation with confirmations
  - Stops and disables virtualcam service
  - Removes all installed files and configuration
  - Optional removal of v4l2loopback kernel module
  - Optional display of commands to remove dependencies
  - Color-coded output for better UX
  - Added to PKGBUILD for AUR package

## [1.1.0] - 2025-11-12

### Added
- 🆕 **Automatic setup script** (`setup-service.sh`) with hardware detection
  - Auto-detects Intel IPU6 or USB webcams
  - Auto-detects v4l2loopback device
  - Generates optimized systemd service
  - Configures v4l2loopback autoload on boot
- 🆕 **Multi-distro support** in `install.sh`
  - Arch Linux / Manjaro
  - Ubuntu / Debian
  - Fedora
  - Automatic dependency detection and installation instructions
- 🆕 **GUI configuration tool** (`configure-gui.sh`)
  - Interactive yad dialogs
  - Configuration file editor
  - Autostart setup
  - Service configuration wizard
- 🆕 **Configuration file** support (`~/.config/webcam-tray/config`)
  - Customizable update interval
  - Service name configuration
  - Icon customization
- 🆕 **Toggle command** to switch service state
- 🆕 **Structured logging** with systemd journal
  - All operations logged to `journalctl -t webcam-tray`
  - Error and info level separation
- 🆕 **XDG Base Directory** compliance
  - Runtime files in `$XDG_RUNTIME_DIR`
  - Config files in `$XDG_CONFIG_HOME`
- 🆕 **PKGBUILD** for Arch User Repository (AUR)
- 🆕 **GitHub Actions CI/CD**
  - Automated testing with ShellCheck
  - Automatic releases on version tags
  - Tarball generation with checksums
- 🆕 **Automated tests** with bats-core
  - Unit tests for all scripts
  - Syntax validation
- 🆕 **Manpage** (`webcam-tray.1`)
- 🆕 **Help command** (`webcam-tray --help`)

### Changed
- ♻️ **Improved `webcam-tray` script**
  - Better PID validation before killing previous instances
  - Configurable update interval
  - Cleaner command handling
  - More robust error handling
- ♻️ **Enhanced `install.sh`**
  - Complete dependency verification (GStreamer, v4l2-utils, v4l2loopback)
  - Distribution detection
  - PATH verification
  - Offers to run setup-service.sh automatically
- ♻️ **Better documentation**
  - Comprehensive README with all features
  - Installation guide for multiple distros
  - Troubleshooting section
  - Contributing guidelines

### Fixed
- 🐛 **Multiple tray instances** - PID validation prevents duplicate processes
- 🐛 **Temporary files in /tmp** - Now uses XDG_RUNTIME_DIR for better compliance
- 🐛 **Missing PATH warning** - Installer checks and warns if ~/.local/bin not in PATH
- 🐛 **Unsafe process killing** - Validates that PID belongs to yad before killing

### Security
- 🔒 PID file validation to prevent killing unrelated processes
- 🔒 Proper cleanup with trap handlers
- 🔒 No hardcoded sensitive paths

## [1.0.0] - 2025-11-11

### Added
- 🎉 Initial release
- ✅ System tray icon with yad
- ✅ Start/Stop service controls
- ✅ Status notifications
- ✅ Log viewer with zenity
- ✅ Auto-update status every 2 seconds
- ✅ Basic systemd service template for Intel IPU6
- ✅ MIT License
- ✅ Basic README

### Supported
- Intel IPU6 cameras (specifically ov02c10 for Samsung Galaxy Book4 Pro)
- Arch Linux primary support
- systemd-based Linux distributions

[1.1.0]: https://github.com/PejarRu/webcam-tray/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/PejarRu/webcam-tray/releases/tag/v1.0.0
