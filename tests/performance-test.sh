#!/bin/bash
# Performance Test: VirtualCam FPS and Latency
# Measures video stream performance

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SERVICE_NAME="virtualcam.service"
LOOPBACK_DEVICE="/dev/video48"
FAILED=0

echo "⚡ VirtualCam Tray - Performance Test"
echo "====================================="
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

info() {
    echo -e "  $1"
}

# Pre-check
if [ ! -f ~/.config/systemd/user/$SERVICE_NAME ]; then
    echo -e "${RED}Error: Service file not found${NC}"
    exit 1
fi

if [ ! -e "$LOOPBACK_DEVICE" ]; then
    echo -e "${RED}Error: Loopback device $LOOPBACK_DEVICE not found${NC}"
    exit 1
fi

# Start service
echo "Starting service..."
systemctl --user start $SERVICE_NAME
sleep 5

if ! systemctl --user is-active --quiet $SERVICE_NAME; then
    echo -e "${RED}Error: Service failed to start${NC}"
    journalctl --user -u $SERVICE_NAME -n 20
    exit 1
fi

pass "Service started"
echo ""

# Test 1: Measure FPS
echo "Test 1: Measuring FPS (10 second sample)..."
FPS_OUTPUT=$(timeout 10 gst-launch-1.0 v4l2src device=$LOOPBACK_DEVICE ! \
    fpsdisplaysink text-overlay=false signal-fps-measurements=true 2>&1 | \
    grep "fps" | tail -n 5 || echo "")

if [ -n "$FPS_OUTPUT" ]; then
    # Extract average FPS
    AVG_FPS=$(echo "$FPS_OUTPUT" | awk '{sum+=$5; count++} END {if(count>0) print sum/count; else print 0}')
    
    info "FPS samples:"
    echo "$FPS_OUTPUT" | head -3
    info "Average FPS: $AVG_FPS"
    
    # Check if FPS >= 25
    if command -v bc &> /dev/null; then
        if (( $(echo "$AVG_FPS >= 25" | bc -l) )); then
            pass "FPS is acceptable (>= 25)"
        elif (( $(echo "$AVG_FPS >= 15" | bc -l) )); then
            warn "FPS is low but usable ($AVG_FPS)"
        else
            fail "FPS too low ($AVG_FPS < 15)"
        fi
    else
        warn "bc not installed, cannot validate FPS threshold"
    fi
else
    warn "Could not measure FPS (stream may not be available)"
fi

echo ""

# Test 2: Measure latency (time to first frame)
echo "Test 2: Measuring latency (time to first frame)..."
START_TIME=$(date +%s%N)
timeout 5 gst-launch-1.0 v4l2src device=$LOOPBACK_DEVICE num-buffers=1 ! fakesink 2>/dev/null || true
END_TIME=$(date +%s%N)

LATENCY_NS=$((END_TIME - START_TIME))
LATENCY_MS=$((LATENCY_NS / 1000000))

info "Latency: ${LATENCY_MS}ms"

if [ $LATENCY_MS -lt 500 ]; then
    pass "Latency is excellent (< 500ms)"
elif [ $LATENCY_MS -lt 1000 ]; then
    pass "Latency is good (< 1s)"
elif [ $LATENCY_MS -lt 3000 ]; then
    warn "Latency is acceptable (< 3s)"
else
    fail "Latency is too high (${LATENCY_MS}ms)"
fi

echo ""

# Test 3: CPU usage
echo "Test 3: Measuring CPU usage..."
GST_PID=$(pgrep -f "gst-launch.*v4l2sink" | head -1 || echo "")

if [ -n "$GST_PID" ]; then
    # Sample CPU usage for 5 seconds
    CPU_SAMPLES=()
    for i in {1..5}; do
        CPU=$(ps -p $GST_PID -o %cpu= 2>/dev/null | tr -d ' ' || echo "0")
        CPU_SAMPLES+=($CPU)
        sleep 1
    done
    
    # Calculate average
    AVG_CPU=$(awk 'BEGIN{sum=0; for(i=0;i<'${#CPU_SAMPLES[@]}';i++) sum+='${CPU_SAMPLES[@]}'; print sum/'${#CPU_SAMPLES[@]}';}' <<< "")
    AVG_CPU=$(echo "${CPU_SAMPLES[@]}" | awk '{sum=0; for(i=1;i<=NF;i++) sum+=$i; print sum/NF}')
    
    info "CPU samples: ${CPU_SAMPLES[*]}"
    info "Average CPU: ${AVG_CPU}%"
    
    if command -v bc &> /dev/null; then
        if (( $(echo "$AVG_CPU < 30" | bc -l) )); then
            pass "CPU usage is low (< 30%)"
        elif (( $(echo "$AVG_CPU < 50" | bc -l) )); then
            pass "CPU usage is acceptable (< 50%)"
        else
            warn "CPU usage is high (${AVG_CPU}%)"
        fi
    else
        warn "bc not installed, cannot validate CPU threshold"
    fi
else
    warn "Could not find gst-launch process"
fi

echo ""

# Test 4: Memory usage
echo "Test 4: Measuring memory usage..."
if [ -n "$GST_PID" ]; then
    MEM_KB=$(ps -p $GST_PID -o rss= | tr -d ' ' || echo "0")
    MEM_MB=$((MEM_KB / 1024))
    
    info "Memory usage: ${MEM_MB} MB"
    
    if [ $MEM_MB -lt 100 ]; then
        pass "Memory usage is low (< 100 MB)"
    elif [ $MEM_MB -lt 200 ]; then
        pass "Memory usage is acceptable (< 200 MB)"
    else
        warn "Memory usage is high (${MEM_MB} MB)"
    fi
else
    warn "Could not measure memory usage"
fi

echo ""

# Test 5: Frame drops
echo "Test 5: Testing for frame drops (30 second test)..."
DROP_OUTPUT=$(timeout 30 gst-launch-1.0 v4l2src device=$LOOPBACK_DEVICE ! \
    video/x-raw,framerate=30/1 ! identity drop-allocation=true ! \
    fpsdisplaysink text-overlay=false 2>&1 | \
    grep -E "dropping|late" || echo "")

if [ -z "$DROP_OUTPUT" ]; then
    pass "No frame drops detected"
else
    warn "Frame drops detected:"
    echo "$DROP_OUTPUT" | head -5
fi

echo ""

# Test 6: Sustained load test
echo "Test 6: Sustained load test (60 seconds)..."
timeout 60 gst-launch-1.0 v4l2src device=$LOOPBACK_DEVICE ! \
    video/x-raw ! queue ! fakesink 2>/dev/null || warn "Sustained test completed with warnings"

if systemctl --user is-active --quiet $SERVICE_NAME; then
    pass "Service remained stable under sustained load"
else
    fail "Service crashed during sustained load"
fi

echo ""

# Test 7: Resolution performance
echo "Test 7: Testing different resolutions..."
for RES in "640x480" "1280x720" "1920x1080"; do
    WIDTH=$(echo $RES | cut -d'x' -f1)
    HEIGHT=$(echo $RES | cut -d'x' -f2)
    
    echo "  Testing $RES..."
    START=$(date +%s%N)
    timeout 3 gst-launch-1.0 v4l2src device=$LOOPBACK_DEVICE ! \
        video/x-raw,width=$WIDTH,height=$HEIGHT ! \
        fakesink 2>/dev/null && \
        info "$RES: Works" || \
        info "$RES: Failed or not supported"
done

echo ""

# Test 8: Service restart time
echo "Test 8: Measuring service restart time..."
START=$(date +%s%N)
systemctl --user restart $SERVICE_NAME
sleep 1

# Wait for service to become active
TIMEOUT=10
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if systemctl --user is-active --quiet $SERVICE_NAME; then
        break
    fi
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
done

END=$(date +%s%N)
RESTART_TIME_MS=$(( (END - START) / 1000000 ))

info "Restart time: ${RESTART_TIME_MS}ms"

if [ $RESTART_TIME_MS -lt 3000 ]; then
    pass "Restart time is fast (< 3s)"
elif [ $RESTART_TIME_MS -lt 5000 ]; then
    pass "Restart time is acceptable (< 5s)"
else
    warn "Restart time is slow (${RESTART_TIME_MS}ms)"
fi

# Cleanup
systemctl --user stop $SERVICE_NAME

echo ""
echo "====================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All performance tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some performance tests failed${NC}"
    exit 1
fi
