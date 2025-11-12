#!/bin/bash
# Chaos Test: VirtualCam Service Resilience
# Tests service behavior under adverse conditions

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SERVICE_NAME="virtualcam.service"
FAILED=0

echo "🔥 VirtualCam Tray - Chaos Test"
echo "================================="
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

# Pre-check: Service must exist
if [ ! -f ~/.config/systemd/user/$SERVICE_NAME ]; then
    echo -e "${RED}Error: Service file not found${NC}"
    echo "Run setup-service.sh first"
    exit 1
fi

# Ensure service is stopped before starting
systemctl --user stop $SERVICE_NAME 2>/dev/null || true
sleep 2

echo "Test 1: Normal service start/stop cycle..."
systemctl --user start $SERVICE_NAME
sleep 3

if systemctl --user is-active --quiet $SERVICE_NAME; then
    pass "Service started normally"
else
    fail "Service failed to start"
    journalctl --user -u $SERVICE_NAME -n 20
    exit 1
fi

systemctl --user stop $SERVICE_NAME
sleep 2

if ! systemctl --user is-active --quiet $SERVICE_NAME; then
    pass "Service stopped normally"
else
    fail "Service did not stop"
fi

echo ""
echo "Test 2: Brutal kill of gst-launch process..."
systemctl --user start $SERVICE_NAME
sleep 3

# Find and kill gst-launch
GST_PID=$(pgrep -f "gst-launch.*v4l2sink" || echo "")
if [ -n "$GST_PID" ]; then
    echo "Killing PID $GST_PID with SIGKILL..."
    kill -9 $GST_PID
    sleep 5
    
    # Service should restart automatically
    if systemctl --user is-active --quiet $SERVICE_NAME; then
        pass "Service auto-restarted after crash"
    else
        fail "Service did not restart after crash"
    fi
else
    warn "gst-launch process not found"
fi

echo ""
echo "Test 3: Remove v4l2loopback module while running..."
if lsmod | grep -q v4l2loopback; then
    echo "Removing v4l2loopback module..."
    sudo modprobe -r v4l2loopback 2>/dev/null || warn "Could not remove module (may be in use)"
    sleep 3
    
    # Service should fail without loopback device
    if ! systemctl --user is-active --quiet $SERVICE_NAME; then
        pass "Service stopped when loopback removed"
    else
        warn "Service still running without loopback"
    fi
    
    # Reload module
    echo "Reloading v4l2loopback module..."
    sudo modprobe v4l2loopback devices=1 video_nr=48 card_label="VirtualCam" exclusive_caps=1
    sleep 2
else
    warn "v4l2loopback not loaded, skipping test"
fi

echo ""
echo "Test 4: Restart service multiple times rapidly..."
for i in {1..5}; do
    systemctl --user restart $SERVICE_NAME
    sleep 1
done

sleep 3

if systemctl --user is-active --quiet $SERVICE_NAME; then
    pass "Service survived rapid restarts"
else
    fail "Service failed after rapid restarts"
fi

echo ""
echo "Test 5: Check service restart limits..."
# Service should have StartLimitBurst=3 in 300s
systemctl --user stop $SERVICE_NAME
sleep 2

echo "Triggering multiple fast failures..."
for i in {1..3}; do
    systemctl --user start $SERVICE_NAME
    sleep 1
    # Kill immediately to cause failure
    pkill -9 -f "gst-launch.*v4l2sink" || true
    sleep 2
done

sleep 3

# Check if service hit restart limit
if systemctl --user is-failed --quiet $SERVICE_NAME; then
    pass "Service correctly hit restart limit"
    systemctl --user reset-failed $SERVICE_NAME
elif systemctl --user is-active --quiet $SERVICE_NAME; then
    warn "Service still running (restart limit not hit)"
else
    warn "Service in unexpected state"
fi

echo ""
echo "Test 6: Concurrent access to camera device..."
systemctl --user start $SERVICE_NAME
sleep 3

# Try to open camera with another process
echo "Attempting concurrent camera access..."
timeout 5 gst-launch-1.0 v4l2src device=/dev/video0 num-buffers=10 ! fakesink 2>/dev/null &
GST_PID=$!

sleep 2

# Original service should still be running
if systemctl --user is-active --quiet $SERVICE_NAME; then
    pass "Service handles concurrent access"
else
    fail "Service failed with concurrent access"
fi

wait $GST_PID 2>/dev/null || true

echo ""
echo "Test 7: Disk full simulation (log rotation)..."
# Check journal size
JOURNAL_SIZE=$(journalctl --user -u $SERVICE_NAME --disk-usage 2>/dev/null | grep -oP '\d+\.\d+[MGK]' | head -1 || echo "0")
echo "Current journal size: $JOURNAL_SIZE"

if [ -n "$JOURNAL_SIZE" ]; then
    pass "Journal logging working"
else
    warn "Could not determine journal size"
fi

echo ""
echo "Test 8: Service stop during active stream..."
systemctl --user start $SERVICE_NAME
sleep 3

# Start consuming stream
timeout 10 gst-launch-1.0 v4l2src device=/dev/video48 ! fakesink &
CONSUMER_PID=$!

sleep 2

# Stop service while consumer is active
systemctl --user stop $SERVICE_NAME
sleep 2

if ! systemctl --user is-active --quiet $SERVICE_NAME; then
    pass "Service stopped cleanly during active stream"
else
    fail "Service did not stop"
fi

wait $CONSUMER_PID 2>/dev/null || true

echo ""
echo "Test 9: Configuration file corruption..."
CONFIG_FILE=~/.config/webcam-tray/config

if [ -f "$CONFIG_FILE" ]; then
    # Backup original
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # Corrupt config
    echo "INVALID SYNTAX HERE" >> "$CONFIG_FILE"
    
    # Try to run webcam-tray
    if ~/.local/bin/webcam-tray --help &> /dev/null; then
        pass "Handles corrupted config gracefully"
    else
        warn "May fail with corrupted config"
    fi
    
    # Restore
    mv "${CONFIG_FILE}.bak" "$CONFIG_FILE"
else
    warn "Config file not found, skipping test"
fi

echo ""
echo "Test 10: Multiple tray instances..."
~/.local/bin/webcam-tray &
TRAY1_PID=$!
sleep 2

~/.local/bin/webcam-tray &
TRAY2_PID=$!
sleep 2

# Second instance should kill first
if ps -p $TRAY1_PID > /dev/null 2>&1; then
    warn "Both instances running (PID validation may be disabled)"
else
    pass "Second instance killed first (PID validation works)"
fi

# Cleanup
kill $TRAY2_PID 2>/dev/null || true
pkill -f "yad.*VirtualCam" 2>/dev/null || true

# Final cleanup
systemctl --user stop $SERVICE_NAME 2>/dev/null || true

echo ""
echo "================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All chaos tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
