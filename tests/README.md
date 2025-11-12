# webcam-tray Tests

This directory contains automated tests for webcam-tray.

## Running Tests

### Install bats-core

**Arch Linux:**
```bash
sudo pacman -S bats
```

**Ubuntu/Debian:**
```bash
sudo apt install bats
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Run all tests

```bash
bats tests/
```

### Run specific test file

```bash
bats tests/test_webcam-tray.bats
```

## Test Coverage

- **test_webcam-tray.bats**: Tests for main webcam-tray script
- **test_install.bats**: Tests for installation scripts

## CI Integration

Tests are automatically run on GitHub Actions for every push and pull request.
