#!/usr/bin/env bats

# Tests for webcam-tray
# Run with: bats tests/test_webcam-tray.bats

setup() {
    # Setup test environment
    export TEST_MODE=1
    export XDG_RUNTIME_DIR="/tmp/webcam-tray-test-$$"
    mkdir -p "$XDG_RUNTIME_DIR"
}

teardown() {
    # Cleanup
    rm -rf "$XDG_RUNTIME_DIR"
}

@test "webcam-tray binary exists and is executable" {
    [ -x ./webcam-tray ]
}

@test "webcam-tray --help shows usage" {
    run ./webcam-tray --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VirtualCam Tray" ]]
}

@test "webcam-tray accepts valid commands" {
    # Test that commands are recognized (may fail if service not present)
    run ./webcam-tray start
    # Exit code doesn't matter, just that it doesn't error on unknown command
    [[ ! "$output" =~ "Comando desconocido" ]]
}

@test "setup-service.sh is executable" {
    [ -x ./setup-service.sh ]
}

@test "install.sh is executable" {
    [ -x ./install.sh ]
}

@test "configure-gui.sh is executable" {
    [ -x ./configure-gui.sh ]
}

@test "README.md exists" {
    [ -f ./README.md ]
}

@test "LICENSE exists" {
    [ -f ./LICENSE ]
}

@test "virtualcam.service.example exists" {
    [ -f ./virtualcam.service.example ]
}

@test "PKGBUILD exists and is valid" {
    [ -f ./PKGBUILD ]
    grep -q "pkgname=webcam-tray" ./PKGBUILD
}

@test "webcam-tray creates config directory" {
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/webcam-tray"
    # This would require running the script, skip for now
    skip "Requires full execution"
}

@test "PID file is created in XDG_RUNTIME_DIR" {
    # This would require running tray mode
    skip "Requires tray mode execution"
}
