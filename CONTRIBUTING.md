# Contributing to VirtualCam Tray

¡Gracias por tu interés en contribuir a VirtualCam Tray! 🎉

## 📋 Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [Cómo Contribuir](#cómo-contribuir)
- [Reportar Bugs](#reportar-bugs)
- [Sugerir Mejoras](#sugerir-mejoras)
- [Pull Requests](#pull-requests)
- [Guía de Estilo](#guía-de-estilo)
- [Testing](#testing)
- [Desarrollo Local](#desarrollo-local)

## 📜 Código de Conducta

Este proyecto se adhiere al [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
Al participar, se espera que respetes este código.

## 🤝 Cómo Contribuir

### Reportar Bugs

Si encuentras un bug:

1. **Verifica** que el bug no haya sido reportado antes en [Issues](https://github.com/PejarRu/webcam-tray/issues)
2. **Abre un nuevo issue** con:
   - Título descriptivo
   - Pasos para reproducir
   - Comportamiento esperado vs actual
   - Información del sistema:
     ```bash
     uname -a
     cat /etc/os-release
     systemctl --version
     yad --version
     ```
   - Logs relevantes:
     ```bash
     journalctl --user -u virtualcam.service -n 50
     journalctl -t webcam-tray -n 50
     ```

### Sugerir Mejoras

Para nuevas features o mejoras:

1. **Abre un issue** con tag `enhancement`
2. Describe:
   - El problema que resuelve
   - Cómo debería funcionar
   - Alternativas consideradas
   - Mockups o ejemplos (si aplica)

## 🔧 Pull Requests

### Proceso

1. **Fork** el repositorio
2. **Crea una rama** desde `master`:
   ```bash
   git checkout -b feature/mi-nueva-feature
   # o
   git checkout -b fix/mi-bugfix
   ```
3. **Haz tus cambios** siguiendo la [Guía de Estilo](#guía-de-estilo)
4. **Ejecuta los tests**:
   ```bash
   bats tests/
   shellcheck webcam-tray setup-service.sh install.sh configure-gui.sh
   ```
5. **Commit** con mensajes descriptivos:
   ```bash
   git commit -m "feat: añadir soporte para Wayland"
   git commit -m "fix: corregir detección de cámara USB"
   ```
6. **Push** a tu fork:
   ```bash
   git push origin feature/mi-nueva-feature
   ```
7. **Abre un Pull Request** en GitHub

### Convenciones de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nueva funcionalidad
- `fix:` Corrección de bug
- `docs:` Cambios en documentación
- `style:` Formato, espacios (no afecta código)
- `refactor:` Refactorización sin cambio de funcionalidad
- `test:` Añadir o corregir tests
- `chore:` Tareas de mantenimiento

Ejemplos:
```bash
feat: añadir comando 'restart' al tray
fix: corregir leak de memoria en update_icon
docs: actualizar README con ejemplos de Fedora
test: añadir tests para configure-gui.sh
```

## 🎨 Guía de Estilo

### Bash/Shell Scripts

- **Indentación**: 4 espacios (no tabs)
- **Quotes**: Usar comillas dobles para variables: `"$VAR"`
- **Funciones**:
  ```bash
  function_name() {
      local var="value"
      echo "$var"
  }
  ```
- **Comentarios**: Describir el "por qué", no el "qué"
  ```bash
  # Good
  # Kill process to free camera device for GStreamer
  fuser -k /dev/video0
  
  # Bad
  # Kill fuser
  fuser -k /dev/video0
  ```
- **Error handling**:
  ```bash
  if ! command_that_might_fail; then
      log_error "Failed to do something"
      return 1
  fi
  ```

### ShellCheck

Todos los scripts deben pasar ShellCheck sin warnings:

```bash
shellcheck -x script.sh
```

Excepciones permitidas (documentar con comentario):
```bash
# shellcheck disable=SC2034  # Variable used in sourced file
VARIABLE="value"
```

### Documentación

- **README.md**: Mantener actualizado con nuevas features
- **Comentarios en código**: Usar para lógica compleja
- **Manpage**: Actualizar `webcam-tray.1` si cambias comandos
- **CHANGELOG.md**: Añadir entrada en sección `[Unreleased]`

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
bats tests/

# Test específico
bats tests/test_webcam-tray.bats

# Con verbose output
bats tests/ --verbose
```

### Añadir Tests

Para nuevas funcionalidades, añade tests en `tests/`:

```bash
@test "nueva funcionalidad funciona correctamente" {
    run ./webcam-tray nueva-funcionalidad
    [ "$status" -eq 0 ]
    [[ "$output" =~ "esperado" ]]
}
```

### Tests Manuales

Antes de abrir PR, prueba manualmente:

1. **Instalación limpia**:
   ```bash
   ./install.sh
   ```
2. **Setup desde cero**:
   ```bash
   ./setup-service.sh
   ```
3. **Tray icon**:
   ```bash
   webcam-tray
   # Probar todos los comandos del menú
   ```
4. **Logs**:
   ```bash
   journalctl -t webcam-tray -f
   journalctl --user -u virtualcam.service -f
   ```

## 💻 Desarrollo Local

### Setup Inicial

```bash
# Clonar tu fork
git clone https://github.com/TU_USUARIO/webcam-tray.git
cd webcam-tray

# Añadir upstream
git remote add upstream https://github.com/PejarRu/webcam-tray.git

# Instalar dependencias de desarrollo
sudo pacman -S bats shellcheck  # Arch
# o
sudo apt install bats shellcheck  # Ubuntu
```

### Flujo de Trabajo

```bash
# Actualizar desde upstream
git checkout master
git pull upstream master

# Crear rama para feature
git checkout -b feature/mi-feature

# Hacer cambios...
# Ejecutar tests
bats tests/
shellcheck *.sh webcam-tray

# Commit y push
git add .
git commit -m "feat: descripción"
git push origin feature/mi-feature
```

### Debugging

```bash
# Modo verbose para scripts
bash -x ./webcam-tray tray

# Ver logs en tiempo real
journalctl -t webcam-tray -f

# Variables de entorno útiles
export GST_DEBUG=3  # GStreamer debug level
export XDG_RUNTIME_DIR=/tmp/test-runtime
```

## 📝 Checklist para PRs

Antes de enviar tu PR, verifica:

- [ ] El código pasa ShellCheck sin errores
- [ ] Los tests pasan (`bats tests/`)
- [ ] Añadiste tests para nueva funcionalidad
- [ ] Actualizaste README.md si es necesario
- [ ] Actualizaste CHANGELOG.md
- [ ] Los commits siguen Conventional Commits
- [ ] El código sigue la guía de estilo
- [ ] Probaste manualmente en tu sistema
- [ ] No hay archivos temporales ni credenciales en el commit

## 🎯 Áreas que Necesitan Ayuda

Contribuciones especialmente bienvenidas en:

- 🌍 **Testing en otras distros** (Ubuntu, Fedora, etc.)
- 🔧 **Soporte para más cámaras** (testing con hardware diferente)
- 🎨 **Mejoras de UI/UX** (iconos, notificaciones)
- 📚 **Traducciones** (inglés completo, otros idiomas)
- 🐛 **Bug fixes** (ver [issues](https://github.com/PejarRu/webcam-tray/issues))
- ⚡ **Optimizaciones de rendimiento**
- 📖 **Documentación** (tutoriales, guías)

## 📞 Contacto

- **Issues**: https://github.com/PejarRu/webcam-tray/issues
- **Discussions**: https://github.com/PejarRu/webcam-tray/discussions

---

¡Gracias por contribuir! 🙏
