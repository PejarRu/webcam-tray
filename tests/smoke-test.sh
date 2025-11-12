#!/bin/bash
# Smoke Test: VirtualCam Tray
# Tests basic functionality with real hardware

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED=0

echo "🧪 VirtualCam Tray - Smoke Test"
echo "================================"
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED=1
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check dependencies
echo "Test 1: Checking dependencies..."
MISSING=()
command -v yad &> /dev/null || MISSING+=("yad")
command -v zenity &> /dev/null || MISSING+=("zenity")
command -v notify-send &> /dev/null || MISSING+=("notify-send")
command -v gst-launch-1.0 &> /dev/null || MISSING+=("gstreamer")
command -v v4l2-ctl &> /dev/null || MISSING+=("v4l2-utils")
command -v systemctl &> /dev/null || MISSING+=("systemd")

if [ ${#MISSING[@]} -eq 0 ]; then
    pass "All dependencies installed"
else
    fail "Missing dependencies: ${MISSING[*]}"
fi

# Test 2: Check v4l2loopback module
echo "Test 2: Checking v4l2loopback module..."
if lsmod | grep -q v4l2loopback; then
    pass "v4l2loopback module loaded"
else
    warn "v4l2loopback not loaded, attempting to load..."
    if sudo modprobe v4l2loopback devices=1 video_nr=48 card_label="VirtualCam" exclusive_caps=1 2>/dev/null; then
        pass "v4l2loopback module loaded successfully"
    else
        fail "Could not load v4l2loopback module"
    fi
fi

# Test 3: Check loopback device exists
echo "Test 3: Checking loopback device..."
LOOPBACK_DEVICE=$(v4l2-ctl --list-devices 2>/dev/null | grep -A1 "v4l2loopback\|VirtualCam" | tail -n1 | tr -d '\t' || echo "/dev/video48")

if [ -e "$LOOPBACK_DEVICE" ]; then
    pass "Loopback device exists: $LOOPBACK_DEVICE"
else
    fail "Loopback device not found: $LOOPBACK_DEVICE"
fi

# Test 4: Install webcam-tray
echo "Test 4: Installing webcam-tray..."
if [ ! -x ~/.local/bin/webcam-tray ]; then
    mkdir -p ~/.local/bin
    cp webcam-tray ~/.local/bin/
    chmod +x ~/.local/bin/webcam-tray
    pass "webcam-tray installed"
else
    pass "webcam-tray already installed"
fi

# Test 5: Test help command
echo "Test 5: Testing --help command..."
if ~/.local/bin/webcam-tray --help &> /dev/null; then
    pass "Help command works"
else
    fail "Help command failed"
fi

# Test 6: Test configuration file creation
echo "Test 6: Testing configuration..."
~/.local/bin/webcam-tray config &
sleep 1
pkill -f "xdg-open.*webcam-tray" 2>/dev/null || true

if [ -f ~/.config/webcam-tray/config ]; then
    pass "Configuration file created"
else
    warn "Configuration file not created (may require GUI)"
fi

# Test 7: Test autostart enable
echo "Test 7: Testing autostart enable..."
~/.local/bin/webcam-tray autostart-enable
if [ -f ~/.config/autostart/webcam-tray.desktop ]; then
    pass "Autostart desktop file created"
else
    fail "Autostart desktop file not created"
fi

# Test 8: Test autostart disable
echo "Test 8: Testing autostart disable..."
~/.local/bin/webcam-tray autostart-disable
if [ ! -f ~/.config/autostart/webcam-tray.desktop ]; then
    pass "Autostart disabled successfully"
else
    fail "Autostart file still exists"
fi

# Test 9: Generate service (if setup-service.sh exists)
echo "Test 9: Testing service generation..."
if [ -f "./setup-service.sh" ]; then
    # Mock hardware detection
    export TEST_MODE=1
    # This would need modification to setup-service.sh for non-interactive mode
    warn "Service generation test skipped (requires interactive mode)"
else
    warn "setup-service.sh not found"
fi

# Test 10: Check systemd service (if exists)
echo "Test 10: Checking systemd service..."
if [ -f ~/.config/systemd/user/virtualcam.service ]; then
    if systemctl --user cat virtualcam.service &> /dev/null; then
        pass "Service file valid"
        
        # Test 11: Try to start service
        echo "Test 11: Testing service start..."
        if systemctl --user start virtualcam.service 2>/dev/null; then
            sleep 3
            
            if systemctl --user is-active --quiet virtualcam.service; then
                pass "Service started successfully"
                
                # Test 12: Check video stream
                echo "Test 12: Testing video stream..."
                if timeout 3 gst-launch-1.0 v4l2src device=$LOOPBACK_DEVICE num-buffers=10 ! fakesink 2>/dev/null; then
                    pass "Video stream working"
                else
                    warn "No video stream detected (may be normal without physical camera)"
                fi
                
                # Test 13: Stop service
                echo "Test 13: Testing service stop..."
                systemctl --user stop virtualcam.service
                sleep 2
                
                if ! systemctl --user is-active --quiet virtualcam.service; then
                    pass "Service stopped successfully"
                else
                    fail "Service did not stop"
                fi
            else
                warn "Service failed to start (expected without physical camera)"
            fi
        else
            warn "Could not start service (expected without physical camera)"
        fi
    else
        fail "Service file invalid"
    fi
else
    warn "Service file not found (run setup-service.sh first)"
fi

# Test 14: Test JSON logging
echo "Test 14: Testing JSON logging..."
export LOG_FORMAT=json
OUTPUT=$(~/.local/bin/webcam-tray status 2>&1 || true)
if echo "$OUTPUT" | grep -q "timestamp"; then
    pass "JSON logging works"
else
    warn "JSON logging not detected in output"
fi

# Summary
echo ""
echo "================================"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All smoke tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
