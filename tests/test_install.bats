#!/usr/bin/env bats

# Tests for install.sh

setup() {
    export TEST_HOME="/tmp/webcam-tray-install-test-$$"
    mkdir -p "$TEST_HOME/.local/bin"
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "install.sh is valid bash" {
    bash -n ./install.sh
}

@test "install.sh detects distribution" {
    # Just check it doesn't crash
    run bash -c "source ./install.sh; detect_distro; echo \$DISTRO"
    [ "$status" -eq 0 ]
}

@test "setup-service.sh is valid bash" {
    bash -n ./setup-service.sh
}

@test "configure-gui.sh is valid bash" {
    bash -n ./configure-gui.sh
}

@test "webcam-tray is valid bash" {
    bash -n ./webcam-tray
}

@test "uninstall.sh exists and is valid bash" {
    [ -f ./uninstall.sh ]
    bash -n ./uninstall.sh
}

